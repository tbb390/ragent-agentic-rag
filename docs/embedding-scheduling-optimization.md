# Embedding 调度优化说明

本文记录本轮针对知识库文档分块与 embedding 调度链路做过的主要优化点，方便后续维护、复盘和继续压测。

## 目标

- 提升批量文档分块时 embedding 阶段的吞吐，减少远程 embedding API 串行等待造成的总耗时。
- 控制并发上限，避免一次性打满 provider、HTTP 连接池或本机线程资源。
- 保持 embedding 结果顺序稳定，确保每个 chunk 回填到原始位置。
- 打通消息投递、消费、执行、日志记录的 `logId`，让单次分块任务更容易追踪。

## 四路有界 embedding 并发

核心实现位于：

- `infra-ai/src/main/java/com/nageoffer/ai/ragent/infra/embedding/AbstractOpenAIStyleEmbeddingClient.java`
- `infra-ai/src/main/java/com/nageoffer/ai/ragent/infra/embedding/AIHubMixEmbeddingClient.java`
- `infra-ai/src/main/java/com/nageoffer/ai/ragent/infra/embedding/SiliconFlowEmbeddingClient.java`

实现方式：

1. `embedBatch` 先读取 `maxBatchSize()`。当输入数量未超过单批上限时，仍然直接调用一次 `doEmbed`。
2. 当输入数量超过单批上限时，将文本按批切成多个 `BatchSlice`，每个 slice 记录：
   - `offset`：该批在原始文本列表中的起始下标；
   - `texts`：本批文本快照，使用 `List.copyOf(...)` 避免后续被外部修改。
3. 根据 `maxBatchConcurrency()` 和 slice 数量计算实际并发数：
   - `concurrency = min(max(1, maxBatchConcurrency()), slices.size())`
   - 默认并发为 1，保持本地或未明确支持并发的 provider 行为不变。
4. 当并发数大于 1 时，使用固定线程池并行提交多个 embedding 请求。
5. 每个请求完成后返回 `BatchResult(offset, vectors)`，再通过 `mergeBatch` 按 offset 写回结果数组。
6. 这样即使不同批次返回顺序不同，最终 `List<List<Float>>` 的顺序仍与原始 chunk 顺序一致。

当前开启四路并发的 provider：

- AIHubMix：`maxBatchSize() = 32`，`maxBatchConcurrency() = 4`
- SiliconFlow：`maxBatchSize() = 32`，`maxBatchConcurrency() = 4`

未重写 `maxBatchConcurrency()` 的客户端保持默认串行。

## 为什么是“有界”并发

这里没有把所有切片无限并发提交，而是使用 provider 级别的最大并发上限。这样做的收益是：

- 大文档不会因为 chunk 很多而创建过多远程请求；
- provider 可以单独配置并发能力，后续扩展时更稳；
- 避免过量并发导致限流、超时、连接池耗尽或线程数膨胀；
- 性能提升集中在远程调用等待时间上，风险边界比较清楚。

## 异常与线程处理

并发分支里额外处理了两类异常：

- `InterruptedException`：恢复线程中断标记，并包装为 `ModelClientException`。
- `ExecutionException`：取子任务原始 cause，包装为 provider 侧失败。

线程池在 `finally` 中 `shutdownNow()`，避免 embedding 批处理结束后残留线程。

## MQ 调度链路日志贯穿

相关位置：

- `bootstrap/src/main/java/com/nageoffer/ai/ragent/knowledge/service/impl/KnowledgeDocumentServiceImpl.java`
- `bootstrap/src/main/java/com/nageoffer/ai/ragent/knowledge/service/KnowledgeDocumentService.java`
- `bootstrap/src/main/java/com/nageoffer/ai/ragent/knowledge/mq/event/KnowledgeDocumentChunkEvent.java`
- `bootstrap/src/main/java/com/nageoffer/ai/ragent/knowledge/mq/KnowledgeDocumentChunkConsumer.java`
- `bootstrap/src/main/java/com/nageoffer/ai/ragent/knowledge/mq/KnowledgeDocumentChunkTransactionChecker.java`

主要变化：

1. `startChunk` 阶段先生成 `logId`，并写入 `KnowledgeDocumentChunkEvent`。
2. 发送 MQ 前，在本地事务里预先创建 `KnowledgeDocumentChunkLogDO`，初始状态为 `PENDING`。
3. 消费者调用 `documentService.executeChunk(docId, logId)`，让执行阶段复用同一条日志。
4. `executeChunk` / `runChunkTask` 按 `logId` 查找已有日志：
   - 已成功的日志会跳过重复投递；
   - 已存在但未成功的日志更新为 `RUNNING` 并刷新开始时间；
   - 兼容旧消息，`logId` 为空时仍会创建新日志。
5. 执行过程中分别记录：
   - 文档读取与 Tika 提取耗时；
   - chunk 切分耗时；
   - embedding 耗时；
   - chunk 与向量持久化耗时；
   - 总耗时。

## 消息体兼容处理

消费者和事务回查里都增加了 `ObjectMapper.convertValue(...)` 兜底：

- 如果 MQ 反序列化后 body 已经是 `KnowledgeDocumentChunkEvent`，直接使用；
- 如果 body 是 `Map` 或其他结构化对象，转换为 `KnowledgeDocumentChunkEvent`。

这个处理能避免泛型消息包装在不同序列化链路下出现强转失败。

## 验证

新增 benchmark 风格测试：

- `infra-ai/src/test/java/com/nageoffer/ai/ragent/infra/embedding/EmbeddingBatchConcurrencyBenchmarkTest.java`

验证点：

- 32 条文本，单批 8 条，模拟每批远程调用延迟 120ms；
- 串行并发为 1，并行并发为 4；
- 断言并行结果与串行结果一致；
- 断言并行版本至少达到 2 倍加速；
- 输出平均耗时、耗时下降比例和 speedup。

可执行命令：

```powershell
.\mvnw.cmd -pl infra-ai -Dtest=EmbeddingBatchConcurrencyBenchmarkTest test
```

## 后续可继续优化

- 将 `maxBatchSize` 和 `maxBatchConcurrency` 下沉到配置文件，按 provider 或模型动态调整。
- 在日志中补充 provider、模型 ID、批次数、实际并发数，便于线上压测观测。
- 对限流类 HTTP 状态增加退避重试，降低瞬时并发冲击。
- 如果后续 provider 支持更大 batch，可通过压测重新评估 `32 x 4` 的组合。
