# Redis 分析

# Redis 用途

项目使用 Spring Data Redis 和 Redisson，主要用途：

- Sa-Token 登录态和会话集成。
- 意图树缓存。
- 查询术语映射缓存。
- 对话摘要分布式锁。
- 全局聊天公平排队限流。
- 流式任务取消通知。
- 文档上传信号量。
- 幂等提交锁和幂等消费。
- Snowflake 分布式 ID 初始化辅助。

# Key 设计

| Key/前缀 | 位置 | 用途 |
| --- | --- | --- |
| `ragent:intent:tree` | `IntentTreeCacheManager` | 缓存意图树，TTL 7 天 |
| `ragent:query-term:mappings` | `QueryTermMappingCacheManager` | 缓存术语映射，TTL 7 天 |
| `ragent:memory:summary:lock:{userId}:{conversationId}` | `JdbcConversationMemorySummaryService` | 摘要压缩分布式锁 |
| `rag:global:chat:semaphore` | `FairDistributedRateLimiter` | 全局聊天并发许可 |
| `rag:global:chat:queue` | `FairDistributedRateLimiter` | 公平排队 ZSET |
| `rag:global:chat:queue:seq` | `FairDistributedRateLimiter` | 排队序号 |
| `rag:global:chat:queue:notify` | `FairDistributedRateLimiter` | permit 释放通知 Topic |
| `rag:global:chat:entry:{requestId}` | `FairDistributedRateLimiter` | 排队 entry 存活标记 |
| `ragent:stream:cancel` | `StreamTaskManager` | 流式任务取消 Pub/Sub Topic |
| `ragent:stream:cancel:{taskId}` | `StreamTaskManager` | 取消状态 |
| `rag:document:upload` | `application.yaml` | 文档上传 Redisson permit semaphore |

# 缓存位置

## 意图树缓存

类：

```text
rag/core/intent/IntentTreeCacheManager.java
```

逻辑：

1. 从 Redis 读取 `ragent:intent:tree`。
2. 缓存不存在时从 `t_intent_node` 加载。
3. 写回 Redis，TTL 7 天。
4. 意图树新增、修改、删除时清除缓存。

## 查询术语映射缓存

类：

```text
rag/core/rewrite/QueryTermMappingCacheManager.java
```

逻辑：

1. 从 Redis 读取 `ragent:query-term:mappings`。
2. 缓存不存在时从 `t_query_term_mapping` 加载。
3. 写回 Redis，TTL 7 天。
4. 后台修改术语映射时清除缓存。

# Session 管理

项目使用 Sa-Token：

```yaml
sa-token:
  token-name: Authorization
  timeout: 2592000
  token-style: simple-uuid
```

依赖：

- `sa-token-spring-boot3-starter`
- `sa-token-redis-template`

Redis 负责 Sa-Token 的 token/session 存储，具体 key 由 Sa-Token 框架管理。

# Agent 上下文缓存

严格来说，Agent 对话上下文主要落 PostgreSQL，而不是 Redis：

- 历史消息：`t_message`
- 会话摘要：`t_conversation_summary`
- 会话主表：`t_conversation`

Redis 参与 Agent 上下文的地方：

- 意图树缓存，影响意图识别上下文。
- 术语映射缓存，影响问题改写。
- 摘要压缩锁，避免同一会话并发压缩。
- 流式任务取消 Topic，支持跨实例取消。
- 聊天排队限流，控制 Agent 执行准入。

# 公平排队限流

核心类：

```text
rag/service/ratelimit/FairDistributedRateLimiter.java
rag/service/ratelimit/ChatQueueLimiter.java
```

机制：

- 使用 Redisson `RPermitExpirableSemaphore` 控制最大并发。
- 使用 `RScoredSortedSet` 作为公平队列。
- 使用 Lua 脚本 `lua/queue_claim_atomic.lua` 原子抢占队首。
- 使用 Redis Topic 唤醒本地 poller。
- 使用 entry marker 避免异常退出造成队列残留。

配置：

```yaml
rag:
  rate-limit:
    global:
      enabled: true
      max-concurrent: 10
      max-wait-seconds: 15
      lease-seconds: 30
      poll-interval-ms: 200
```

# 文档上传限流

核心类：

- `SemaphoreInitializer`
- `UploadRateLimitFilter`

配置：

```yaml
rag:
  semaphore:
    document-upload:
      name: rag:document:upload
      max-concurrent: 10
      max-wait-seconds: 5
      lease-seconds: 300
```

# 流式任务取消

核心类：

```text
rag/service/handler/StreamTaskManager.java
```

用途：

- 绑定 `taskId` 和 `StreamCancellationHandle`。
- 前端调用 `/rag/v3/stop` 后发布取消事件。
- 多实例情况下通过 Redis Topic 同步取消。

# 幂等

核心类：

- `IdempotentSubmitAspect`
- `IdempotentConsumeAspect`

用途：

- 防重复提交。
- MQ 消费幂等。
- RAG chat 接口使用 `@IdempotentSubmit`，防止同一用户并发提交多个会话请求。
