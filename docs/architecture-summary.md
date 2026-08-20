# 架构图总览

# 1. 总体架构图

```mermaid
flowchart TD
    U[用户/管理员] --> FE[React 前端]
    FE --> API[bootstrap 主服务 9090 /api/ragent]
    API --> FW[framework 通用基础设施]
    API --> AI[infra-ai 模型编排]
    API --> DB[(PostgreSQL)]
    API --> V[(pgvector / Milvus)]
    API --> R[(Redis / Redisson)]
    API --> MQ[RocketMQ]
    API --> S3[RustFS/S3]
    API --> MCPClient[MCP Client]
    MCPClient --> MCP[mcp-server 9099 /mcp]
    MCP --> Tools[Weather / Ticket / Sales Tools]
    AI --> Providers[Ollama / Bailian / AIHubMix / SiliconFlow]
```

# 2. 模块关系图

```mermaid
flowchart LR
    Root[ragent parent pom] --> Bootstrap[bootstrap]
    Root --> Framework[framework]
    Root --> InfraAI[infra-ai]
    Root --> McpServer[mcp-server]
    Bootstrap --> Framework
    Bootstrap --> InfraAI
    InfraAI --> Framework
    Bootstrap -. runtime HTTP MCP .-> McpServer
    Frontend[frontend] -. HTTP API .-> Bootstrap
```

# 3. Agent 流程图

```mermaid
flowchart TD
    A[Chat Request] --> B[ChatQueueLimiter]
    B --> C[TraceRunner]
    C --> D[StreamChatPipeline]
    D --> E[Load Memory]
    E --> F[Rewrite and Split]
    F --> G[Resolve Intent]
    G --> H{Guidance?}
    H -- Yes --> I[SSE Guidance]
    H -- No --> J{Intent Type}
    J -- SYSTEM --> K[System LLM Response]
    J -- KB --> L[Knowledge Retrieval]
    J -- MCP --> M[Tool Execution]
    L --> N[Prompt Context]
    M --> N
    K --> O[LLM Stream]
    N --> O
    O --> P[SSE Events]
    P --> Q[Persist Message / Summary]
```

# 4. RAG 流程图

```mermaid
flowchart TD
    A[Question] --> B[Memory]
    B --> C[Query Rewrite]
    C --> D[Intent Classify]
    D --> E[MultiChannelRetrievalEngine]
    E --> F[IntentDirectedSearchChannel]
    E --> G[VectorGlobalSearchChannel]
    F --> H[RetrieverService]
    G --> H
    H --> I[EmbeddingService]
    I --> J[(Vector Store)]
    J --> K[Retrieved Chunks]
    K --> L[Deduplication]
    L --> M[Rerank]
    M --> N[ContextFormatter]
    N --> O[RAGPromptService]
    O --> P[LLMService]
    P --> Q[Answer]
```

# 5. MCP 流程图

```mermaid
flowchart TD
    A[mcp-server 启动] --> B[ToolSpecification Beans]
    B --> C[McpSyncServer]
    C --> D[/mcp]
    E[bootstrap 启动] --> F[McpClientAutoConfiguration]
    F --> G[listTools]
    G --> H[DefaultMcpToolRegistry]
    I[用户问题] --> J[命中 MCP 意图]
    J --> K[LLM 参数抽取]
    K --> L[McpClientToolExecutor]
    L --> D
    D --> M[Tool Handler]
    M --> N[CallToolResult]
    N --> O[MCP Context]
    O --> P[Prompt + LLM]
```

# 6. 请求调用图

```mermaid
sequenceDiagram
    participant FE as Frontend
    participant C as Controller
    participant S as Service
    participant P as Pipeline
    participant R as Retrieval
    participant DB as Database
    participant AI as LLM/Embedding

    FE->>C: /rag/v3/chat
    C->>S: streamChat
    S->>P: execute(ctx)
    P->>DB: load memory
    P->>AI: rewrite / intent classify
    P->>R: retrieve
    R->>AI: embedding
    R->>DB: vector search
    R-->>P: RetrievalContext
    P->>AI: streamChat
    AI-->>FE: SSE chunks
```
