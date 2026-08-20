# 请求调用链分析

# 核心业务流程 1：RAG 流式问答

入口：

```text
GET /api/ragent/rag/v3/chat?question=...&conversationId=...&deepThinking=false
```

调用链：

1. `RAGChatController.chat`
2. `RAGChatServiceImpl.streamChat`
3. `ChatQueueLimiter.enqueue`
4. `StreamChatTraceRunner.run`
5. `StreamChatPipeline.execute`
6. `ConversationMemoryService.loadAndAppend`
7. `QueryRewriteService.rewriteWithSplit`
8. `IntentResolver.resolve`
9. `IntentGuidanceService.detectAmbiguity`
10. `RetrievalEngine.retrieve`
11. `MultiChannelRetrievalEngine.retrieveKnowledgeChannels`
12. `SearchChannel.search`
13. `RetrieverService.retrieve`
14. `EmbeddingService.embed`
15. `PgRetrieverService` 或 `MilvusRetrieverService`
16. `DeduplicationPostProcessor`
17. `RerankPostProcessor`
18. `RAGPromptService.buildStructuredMessages`
19. `LLMService.streamChat`
20. `StreamChatEventHandler` 通过 SSE 推送前端

```mermaid
sequenceDiagram
    participant Browser
    participant Controller as RAGChatController
    participant Service as RAGChatServiceImpl
    participant Limiter as ChatQueueLimiter
    participant Pipeline as StreamChatPipeline
    participant Memory as ConversationMemoryService
    participant Rewrite as QueryRewriteService
    participant Intent as IntentResolver
    participant Retrieval as RetrievalEngine
    participant Vector as Pg/Milvus Retriever
    participant Prompt as RAGPromptService
    participant LLM as LLMService
    participant DB as PostgreSQL/Vector DB

    Browser->>Controller: GET /rag/v3/chat
    Controller->>Service: streamChat(question, conversationId)
    Service->>Limiter: enqueue()
    Limiter->>Pipeline: execute(ctx)
    Pipeline->>Memory: loadAndAppend()
    Memory->>DB: load conversation/history/summary
    Pipeline->>Rewrite: rewriteWithSplit()
    Pipeline->>Intent: resolve()
    Intent->>DB: load intent tree if Redis miss
    Pipeline->>Retrieval: retrieve(subIntents)
    Retrieval->>Vector: retrieve()
    Vector->>LLM: embed(query)
    Vector->>DB: vector similarity search
    Retrieval->>Prompt: format context
    Pipeline->>Prompt: buildStructuredMessages()
    Pipeline->>LLM: streamChat()
    LLM-->>Browser: SSE chunks
```

# 核心业务流程 2：MCP 工具型问答

当意图节点是 MCP 类型时，请求不会只走知识库检索，而是触发工具调用。

调用链：

1. `RAGChatController.chat`
2. `StreamChatPipeline.execute`
3. `IntentResolver.resolve`
4. `RetrievalEngine.retrieve`
5. `NodeScoreFilters.mcp`
6. `executeMcpTools`
7. `McpToolRegistry.getExecutor`
8. `LLMMcpParameterExtractor.extractParameters`
9. `McpClientToolExecutor.execute`
10. 远程 `mcp-server /mcp`
11. `WeatherMcpExecutor` / `TicketMcpExecutor` / `SalesMcpExecutor`
12. `ContextFormatter.formatMcpContext`
13. `RAGPromptService`
14. `LLMService.streamChat`

```mermaid
flowchart TD
    A[用户问题] --> B[意图识别]
    B --> C{命中 MCP 意图?}
    C -- 否 --> D[知识库检索]
    C -- 是 --> E[读取意图节点 mcpToolId]
    E --> F[McpToolRegistry 查找 Executor]
    F --> G[LLM 抽取 Tool 参数]
    G --> H[McpClientToolExecutor callTool]
    H --> I[mcp-server /mcp]
    I --> J[具体 Tool 执行]
    J --> K[工具结果格式化]
    D --> L[KB 上下文]
    K --> M[MCP 上下文]
    L --> N[Prompt 组装]
    M --> N
    N --> O[LLM 生成答案]
```

# 核心业务流程 3：知识文档上传与入库

入口在 `KnowledgeDocumentController`，文档处理最终进入入库 Pipeline 或知识库分块逻辑。

核心类：

- `KnowledgeDocumentController`
- `KnowledgeDocumentServiceImpl`
- `KnowledgeDocumentChunkConsumer`
- `IngestionEngine`
- `FetcherNode`
- `ParserNode`
- `ChunkerNode`
- `IndexerNode`

```mermaid
sequenceDiagram
    participant Admin
    participant Controller as KnowledgeDocumentController
    participant Service as KnowledgeDocumentServiceImpl
    participant MQ as RocketMQ
    participant Consumer as KnowledgeDocumentChunkConsumer
    participant Engine as IngestionEngine
    participant Parser as Parser/Chunker/Indexer
    participant DB as PostgreSQL
    participant Vector as pgvector/Milvus

    Admin->>Controller: 上传文档
    Controller->>Service: create/upload
    Service->>DB: 保存文档元数据
    Service->>MQ: 发送分块事件
    MQ->>Consumer: 消费事件
    Consumer->>Engine: execute pipeline
    Engine->>Parser: Fetcher/Parser/Chunker
    Parser->>Vector: 写入向量
    Parser->>DB: 写入 Chunk 和日志
```

# 核心业务流程 4：后台查询知识库文档

调用链：

1. `KnowledgeBaseController` / `KnowledgeDocumentController` / `KnowledgeChunkController`
2. 对应 Service
3. MyBatis-Plus Mapper
4. PostgreSQL 表

```mermaid
flowchart LR
    A[Admin 页面] --> B[Knowledge Controller]
    B --> C[Knowledge Service]
    C --> D[Knowledge Mapper]
    D --> E[(PostgreSQL)]
    E --> D --> C --> B --> A
```

# 核心业务流程 5：会话历史查询

调用链：

1. `ConversationController`
2. `ConversationGroupService` / `ConversationMessageService`
3. `ConversationMapper` / `ConversationMessageMapper`
4. `t_conversation` / `t_message`

```mermaid
flowchart TD
    A[前端会话列表] --> B[ConversationController]
    B --> C[ConversationGroupService]
    C --> D[ConversationMapper]
    D --> E[t_conversation]
    B --> F[ConversationMessageService]
    F --> G[ConversationMessageMapper]
    G --> H[t_message]
```
