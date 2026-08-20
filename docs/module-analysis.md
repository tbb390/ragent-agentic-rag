# 模块目录树

```text
ragent
├── bootstrap
│   └── src/main/java/com/nageoffer/ai/ragent
│       ├── admin
│       ├── core
│       ├── ingestion
│       ├── knowledge
│       ├── rag
│       └── user
├── framework
│   └── src/main/java/com/nageoffer/ai/ragent/framework
│       ├── cache
│       ├── config
│       ├── context
│       ├── convention
│       ├── database
│       ├── distributedid
│       ├── errorcode
│       ├── exception
│       ├── idempotent
│       ├── mq
│       ├── trace
│       └── web
├── infra-ai
│   └── src/main/java/com/nageoffer/ai/ragent/infra
│       ├── chat
│       ├── config
│       ├── embedding
│       ├── enums
│       ├── http
│       ├── model
│       ├── rerank
│       ├── token
│       └── util
├── mcp-server
│   └── src/main/java/com/nageoffer/ai/ragent/mcp
│       ├── config
│       └── executor
└── frontend
    └── src
        ├── components
        ├── hooks
        ├── pages
        ├── services
        ├── stores
        └── utils
```

# 每个模块职责

## bootstrap

功能：

- 主业务服务和主启动入口。
- 聚合 RAG、知识库、入库 Pipeline、用户认证、后台统计。
- 负责 Web API、数据库实体、Mapper、业务服务、调度任务和 RAG 主链路编排。

核心代码：

- 启动类：`RagentApplication`
- RAG：`rag/controller/RAGChatController`、`rag/service/impl/RAGChatServiceImpl`、`rag/service/pipeline/StreamChatPipeline`
- 检索：`rag/core/retrieve/RetrievalEngine`、`MultiChannelRetrievalEngine`
- MCP Client：`rag/core/mcp/McpClientAutoConfiguration`、`DefaultMcpToolRegistry`
- 入库：`ingestion/engine/IngestionEngine`、`ingestion/node/*Node`
- 知识库：`knowledge/service/impl/KnowledgeDocumentServiceImpl`
- 向量：`rag/core/vector/PgVectorStoreService`、`MilvusVectorStoreService`

被谁依赖：

- 作为主应用最终启动模块，不被其它后端模块依赖。

依赖谁：

- `framework`
- `infra-ai`
- Spring Web、JDBC、Validation、Tika、PostgreSQL、pgvector、Milvus、S3、MCP SDK

为什么这样设计：

- 把业务编排集中在一个启动模块，便于作为单体应用交付。
- 基础设施和模型调用独立成模块，业务层可以更换模型、向量库和通用组件。

## framework

功能：

- 提供业务无关的通用基础能力。
- 包括统一返回、异常体系、MyBatis-Plus 配置、Redis 序列化、分布式 ID、幂等、RocketMQ 生产者、用户上下文、RAG Trace 注解和 SSE 发送封装。

核心代码：

- `web/Results`、`web/SseEmitterSender`、`web/GlobalExceptionHandler`
- `database/DataBaseConfiguration`、`database/MyMetaObjectHandler`
- `distributedid/CustomIdentifierGenerator`、`SnowflakeIdInitializer`
- `idempotent/IdempotentSubmitAspect`、`IdempotentConsumeAspect`
- `mq/producer/RocketMQProducerAdapter`
- `trace/RagTraceContext`、`RagTraceNode`、`RagTraceRoot`

被谁依赖：

- `bootstrap`
- `infra-ai`

依赖谁：

- Spring Web、Redis、Redisson、MyBatis-Plus、Sa-Token、RocketMQ、TTL、Hutool、Guava。

为什么这样设计：

- 抽离横切能力，降低业务模块样板代码。
- 让 RAG、知识库、用户等不同业务域共享统一错误码、上下文、Trace 和幂等机制。

## infra-ai

功能：

- 封装大模型、Embedding、Rerank、模型路由和供应商差异。
- 负责 HTTP 调用 OpenAI compatible 接口、流式解析、模型选择、熔断健康状态。

核心代码：

- Chat：`LLMService`、`RoutingLLMService`、`ChatClient`、`AbstractOpenAIStyleChatClient`
- Embedding：`EmbeddingService`、`RoutingEmbeddingService`、`EmbeddingClient`
- Rerank：`RerankService`、`RoutingRerankService`、`BaiLianRerankClient`、`NoopRerankClient`
- 模型路由：`ModelSelector`、`ModelRoutingExecutor`、`ModelHealthStore`
- 配置：`AIModelProperties`

被谁依赖：

- `bootstrap`

依赖谁：

- `framework`
- OkHttp

为什么这样设计：

- 模型供应商变化频繁，业务层不应直接依赖供应商 API。
- 通过候选模型、优先级和健康状态实现自动降级。

## mcp-server

功能：

- 独立 MCP Server。
- 通过 `/mcp` 暴露工具列表和工具调用接口。
- 当前提供天气、工单、销售数据三个演示工具。

核心代码：

- 启动类：`McpServerApplication`
- 服务配置：`config/McpServerConfig`
- 工具：`executor/WeatherMcpExecutor`、`TicketMcpExecutor`、`SalesMcpExecutor`

被谁依赖：

- 逻辑上被主服务 `bootstrap` 的 MCP Client 调用。
- Maven 上不被 `bootstrap` 直接依赖，两者运行时通过 HTTP 通信。

依赖谁：

- Spring Web
- MCP Java SDK

为什么这样设计：

- MCP Tool 可以与主业务解耦部署。
- 主服务只通过标准 MCP 协议发现和调用工具，便于后续接入外部工具服务。

## frontend

功能：

- 聊天页、登录页、管理后台。
- 管理知识库、文档、Chunk、意图树、样例问题、术语映射、RAG Trace、系统设置、用户。

核心代码：

- 页面：`src/pages/ChatPage.tsx`、`src/pages/admin/**`
- API：`src/services/*Service.ts`
- 流式回答：`src/hooks/useStreamResponse.ts`、`src/hooks/useChat.ts`
- 状态：`src/stores/authStore.ts`、`chatStore.ts`

被谁依赖：

- 独立前端，不被后端模块依赖。

依赖谁：

- React、Vite、TypeScript、Tailwind、组件库封装。

为什么这样设计：

- 前后端分离，后端专注 API 和 AI 编排，前端提供普通用户问答和管理员控制台。

# bootstrap 内部业务模块

## admin

- 功能：后台 Dashboard 统计。
- 核心代码：`DashboardController`、`DashboardServiceImpl`
- 依赖：RAG Trace、知识库、消息反馈等表。

## core

- 功能：文档解析和文本切分基础能力。
- 核心代码：`parser/TikaDocumentParser`、`chunk/ChunkingStrategyFactory`、`FixedSizeTextChunker`、`StructureAwareTextChunker`、`ChunkEmbeddingService`
- 依赖：Tika、EmbeddingService。

## ingestion

- 功能：可编排文档入库 Pipeline。
- 核心代码：`IngestionEngine`、`FetcherNode`、`ParserNode`、`EnhancerNode`、`ChunkerNode`、`EnricherNode`、`IndexerNode`
- 依赖：core/parser、core/chunk、rag/vector、infra-ai。

## knowledge

- 功能：知识库、文档、Chunk、定时刷新、上传限流、RocketMQ 分块处理。
- 核心代码：`KnowledgeBaseController`、`KnowledgeDocumentController`、`KnowledgeDocumentServiceImpl`、`KnowledgeDocumentChunkConsumer`
- 依赖：ingestion、rag/vector、framework/mq、Redisson。

## rag

- 功能：问答主链路、检索、意图、记忆、Prompt、MCP Client、Trace、限流。
- 核心代码：`StreamChatPipeline`、`RetrievalEngine`、`DefaultIntentClassifier`、`RAGPromptService`、`DefaultConversationMemoryService`
- 依赖：infra-ai、knowledge、framework、Redis、PostgreSQL、pgvector/Milvus、MCP。

## user

- 功能：登录、认证、用户管理、用户上下文。
- 核心代码：`AuthController`、`UserController`、`AuthServiceImpl`、`UserServiceImpl`、`UserContextInterceptor`
- 依赖：Sa-Token、MyBatis-Plus。

# common/domain/application/adapter 判断

项目没有以 `common`、`domain`、`application`、`adapter` 作为顶层 Maven 模块。等价职责分散如下：

- common：由 `framework` 承担。
- domain：由 `bootstrap` 下 `rag`、`knowledge`、`ingestion` 等领域包承担。
- application：由各领域 `service` 和 `service/impl` 承担。
- adapter：由 `controller`、`dao/mapper`、`infra-ai`、`mcp-server` 承担。
