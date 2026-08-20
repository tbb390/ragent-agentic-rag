# 源码阅读路线
# 第 1 天：项目全景和启动

阅读文件：

- `README.md`
- `pom.xml`
- `bootstrap/pom.xml`
- `framework/pom.xml`
- `infra-ai/pom.xml`
- `mcp-server/pom.xml`
- `bootstrap/src/main/java/com/nageoffer/ai/ragent/RagentApplication.java`
- `bootstrap/src/main/resources/application.yaml`

阅读模块：

- 根项目
- bootstrap
- framework
- infra-ai
- mcp-server

学习目标：

- 理解 Maven 多模块依赖。
- 理解主服务和 MCP 服务的关系。
- 理解 PostgreSQL、Redis、RocketMQ、pgvector/Milvus、模型供应商配置。

预计耗时：2-3 小时。

# 第 2 天：一次 RAG 请求怎么跑

阅读文件：

- `rag/controller/RAGChatController.java`
- `rag/service/impl/RAGChatServiceImpl.java`
- `rag/service/pipeline/StreamChatPipeline.java`
- `rag/service/pipeline/StreamChatContext.java`
- `rag/service/handler/StreamChatEventHandler.java`
- `rag/service/handler/StreamCallbackFactory.java`

学习目标：

- 理解 SSE 流式问答入口。
- 理解一次请求如何创建 conversationId、taskId、callback。
- 理解 Pipeline 阶段顺序。

预计耗时：3 小时。

# 第 3 天：Memory、Rewrite、Intent

阅读文件：

- `rag/core/memory/DefaultConversationMemoryService.java`
- `rag/core/memory/JdbcConversationMemoryStore.java`
- `rag/core/memory/JdbcConversationMemorySummaryService.java`
- `rag/core/rewrite/MultiQuestionRewriteService.java`
- `rag/core/rewrite/QueryTermMappingService.java`
- `rag/core/intent/DefaultIntentClassifier.java`
- `rag/core/intent/IntentResolver.java`
- `rag/core/intent/IntentTreeCacheManager.java`

学习目标：

- 理解会话历史和摘要如何进入上下文。
- 理解问题改写和拆分。
- 理解意图树、Redis 缓存和 LLM 分类。

预计耗时：4 小时。

# 第 4 天：检索和向量库

阅读文件：

- `rag/core/retrieve/RetrievalEngine.java`
- `rag/core/retrieve/MultiChannelRetrievalEngine.java`
- `rag/core/retrieve/channel/SearchChannel.java`
- `rag/core/retrieve/channel/IntentDirectedSearchChannel.java`
- `rag/core/retrieve/channel/VectorGlobalSearchChannel.java`
- `rag/core/retrieve/PgRetrieverService.java`
- `rag/core/vector/PgVectorStoreService.java`
- `rag/core/retrieve/postprocessor/DeduplicationPostProcessor.java`
- `rag/core/retrieve/postprocessor/RerankPostProcessor.java`

学习目标：

- 理解多路检索。
- 理解意图定向检索与全局检索。
- 理解 pgvector 查询 SQL。
- 理解去重和重排。

预计耗时：4 小时。

# 第 5 天：文档入库 Pipeline

阅读文件：

- `ingestion/engine/IngestionEngine.java`
- `ingestion/node/IngestionNode.java`
- `ingestion/node/FetcherNode.java`
- `ingestion/node/ParserNode.java`
- `ingestion/node/ChunkerNode.java`
- `ingestion/node/IndexerNode.java`
- `core/parser/TikaDocumentParser.java`
- `core/chunk/FixedSizeTextChunker.java`
- `core/chunk/strategy/StructureAwareTextChunker.java`
- `core/chunk/ChunkEmbeddingService.java`

学习目标：

- 理解文档如何从来源进入系统。
- 理解节点式 Pipeline。
- 理解解析、切分、Embedding、索引写入。

预计耗时：4 小时。

# 第 6 天：MCP 和 Agentic 编排

阅读文件：

- `rag/core/mcp/McpToolExecutor.java`
- `rag/core/mcp/DefaultMcpToolRegistry.java`
- `rag/core/mcp/McpClientAutoConfiguration.java`
- `rag/core/mcp/McpClientToolExecutor.java`
- `rag/core/mcp/LLMMcpParameterExtractor.java`
- `mcp-server/config/McpServerConfig.java`
- `mcp-server/executor/WeatherMcpExecutor.java`
- `mcp-server/executor/TicketMcpExecutor.java`
- `mcp-server/executor/SalesMcpExecutor.java`

学习目标：

- 理解 MCP Server 如何暴露工具。
- 理解主服务如何发现和注册远程工具。
- 理解 LLM 参数抽取和工具结果注入 Prompt。

预计耗时：3-4 小时。

# 第 7 天：工程化能力和面试复盘

阅读文件：

- `rag/service/ratelimit/FairDistributedRateLimiter.java`
- `rag/service/ratelimit/ChatQueueLimiter.java`
- `rag/service/handler/StreamTaskManager.java`
- `rag/aop/RagTraceAspect.java`
- `rag/trace/StreamChatTraceRunner.java`
- `framework/idempotent/IdempotentSubmitAspect.java`
- `framework/mq/producer/RocketMQProducerAdapter.java`
- `resources/database/schema_pg.sql`

学习目标：

- 理解 Redis 公平排队限流。
- 理解流式任务取消。
- 理解 Trace 和幂等。
- 整理项目亮点和面试表达。

预计耗时：4 小时。
