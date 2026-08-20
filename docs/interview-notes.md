# 简历与面试价值

# 项目亮点

- 企业级 Agentic RAG 平台，不是简单 Embedding + Vector Search Demo。
- 完整覆盖文档入库、向量检索、意图识别、MCP 工具调用、对话记忆、流式输出、后台管理。
- Java 技术栈实现 AI 应用工程化，适合 Java 后端转 AI 应用方向。
- 主服务模块化单体 + 独立 MCP Server，架构清晰且容易讲清楚。
- 支持 pgvector 和 Milvus 两种向量存储。
- 支持多模型供应商路由、优先级、失败熔断和降级。
- Redis 实现公平排队限流、任务取消、缓存、分布式锁和上传信号量。
- RocketMQ 支持知识文档分块处理。
- RAG Trace 可观测，能追踪 rewrite、intent、retrieve、LLM 等节点。

# 技术亮点

- 多路检索：意图定向检索 + 全局向量检索。
- 检索后处理：去重 + Rerank。
- 意图树：LLM 对树形意图叶子节点打分，区分 KB/MCP/SYSTEM。
- Agentic 编排：根据意图动态选择知识库检索、MCP 工具调用或系统回答。
- MCP 集成：主服务作为 MCP Client，独立服务暴露 MCP Server 和 Tool。
- Prompt 编排：KB only、MCP only、KB+MCP、System 多场景模板。
- 记忆压缩：最近历史 + 摘要，避免上下文无限增长。
- 模型工程：Chat/Embedding/Rerank 抽象、供应商适配、优先级路由、健康状态。
- 入库 Pipeline：Fetcher、Parser、Enhancer、Chunker、Enricher、Indexer 节点化。
- 并发控制：Redisson semaphore + ZSET 公平队列 + Lua 原子抢占。

# 可写进简历的内容

## 个人性能优化：Embedding 分批有界并发

> 针对大文档入库时 Embedding 请求超过供应商单批上限后串行执行的性能瓶颈，将向量化链路改造为“固定大小分批 + 4 路有界并发 + 按索引保序归并”，并在异常时取消剩余批次，避免无效请求持续占用连接。基于 32 条文本、单批 8 条、120ms 模拟模型延迟的预热后 5 轮 A/B 基准，平均耗时由 510ms 降至 136ms，降低约 73%，吞吐提升 3.75 倍，且向量数量与顺序一致性测试通过。

真实链路验证：使用 SiliconFlow `Qwen/Qwen3-Embedding-8B`、pgvector、RocketMQ 和 RustFS 对 50 份文档执行异步入库，累计生成 2450 个向量块，成功率 100%；Embedding P50 为 16.96s、P95 为 27.86s，端到端 P95 为 28.04s。真实数据用于证明优化链路在外部模型长尾延迟下的稳定性，提升比例仍以同环境 A/B 基准为准。

面试说明：约 73% 和 3.75 倍来自隔离网络波动后的算法 A/B 基准；真实供应商测试用于规模和稳定性验证，不能把两种测试口径混为生产性能提升。

示例 1：

> 参与设计并实现企业级 Agentic RAG 平台，基于 Spring Boot 3、PostgreSQL/pgvector、Redis、RocketMQ 和 MCP Java SDK，完成知识库问答、文档入库、向量检索、意图识别、MCP 工具调用和 SSE 流式输出等核心能力。

示例 2：

> 设计多路检索架构，实现意图定向检索与全局向量检索并行召回，并通过去重和 Rerank 后处理提升检索精度；支持 pgvector/Milvus 两种向量存储切换。

示例 3：

> 实现 Agentic RAG 编排链路，将 Query Rewrite、Intent Resolver、Memory、MCP Tool 调用、Prompt Builder 和 LLM Streaming 组合为可观测流水线，并通过 RAG Trace 记录每个节点耗时和错误。

示例 4：

> 基于 Redisson 设计全局公平排队限流机制，使用 PermitExpirableSemaphore、ZSET、Pub/Sub 和 Lua 脚本控制模型调用并发，支持排队超时、任务取消和跨实例唤醒。

示例 5：

> 封装多供应商模型路由能力，抽象 Chat、Embedding、Rerank 客户端，支持模型优先级、失败计数、三态熔断和自动降级。

# 面试高频问题

## 这个项目和普通 RAG Demo 的区别是什么？

普通 Demo 通常只有 Embedding、向量检索和 LLM 生成。本项目包含文档入库 Pipeline、意图树、多路检索、MCP 工具调用、会话记忆压缩、模型路由降级、并发限流、Trace 和管理后台，是完整工程闭环。

## 为什么要做问题改写？

用户问题可能口语化、依赖上下文或包含多个子问题。改写可以补全上下文、规范检索表达，拆分可以让每个子问题分别识别意图和检索，提升召回质量。

## 意图识别怎么做？

从 `t_intent_node` 加载树形意图，缓存到 Redis。`DefaultIntentClassifier` 将叶子节点信息组织进 Prompt，让 LLM 输出每个意图的 score。`IntentResolver` 过滤低分结果并控制总意图数量。

## 多路检索怎么实现？

`MultiChannelRetrievalEngine` 收集所有 `SearchChannel` Bean，按配置判断启用，使用线程池并行执行。当前有 `IntentDirectedSearchChannel` 和 `VectorGlobalSearchChannel`，结果经过去重和 Rerank。

## MCP 在项目里怎么用？

`mcp-server` 暴露 `/mcp` 和工具。主服务启动时通过 `McpClientAutoConfiguration` 连接 MCP Server，调用 `listTools` 注册工具。用户问题命中 MCP 意图后，用 LLM 抽取参数并调用 `callTool`，工具结果进入 Prompt。

## 会话记忆怎么控制 Token？

只保留最近若干轮历史，默认 4 轮；超过阈值后异步生成摘要，摘要和最近历史一起作为上下文。摘要写入 `t_conversation_summary`，并用 Redis lock 避免并发压缩。

## 为什么默认用 pgvector，还保留 Milvus？

pgvector 部署简单，适合本地和中小规模场景；Milvus 更适合大规模向量检索。项目用 `VectorStoreService` 和 `RetrieverService` 抽象，让两者可切换。

## 如何保证模型服务不稳定时系统可用？

`infra-ai` 使用候选模型列表、优先级、失败阈值和健康状态。模型失败达到阈值后进入熔断状态，冷却后半开探测，失败则继续熔断，成功则恢复。

# 项目难点

- RAG 链路很长，任何环节失败都需要降级和可观测。
- 多模型供应商接口差异需要统一抽象。
- 文档解析和切分质量影响最终回答质量。
- 多路检索结果合并、去重、重排需要设计稳定策略。
- MCP 工具参数抽取需要受 schema 和业务 Prompt 双重约束。
- SSE 流式输出需要处理取消、超时、首包、异常和消息落库。
- 高并发下模型调用成本高，需要公平排队和限流。

# 架构亮点

- `framework`、`infra-ai`、`bootstrap` 分离，业务和基础设施边界清楚。
- `SearchChannel`、`SearchResultPostProcessor`、`McpToolExecutor`、`IngestionNode` 都是可扩展接口。
- 入库 Pipeline 与 RAG 查询链路分离。
- MCP Server 独立运行，主服务通过协议发现工具。
- Redis 不只做缓存，还承担锁、信号量、队列、Topic 等协调能力。
- Trace 表把 RAG 调用链可视化，便于定位召回差、首包慢、模型失败等问题。
