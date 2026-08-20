# 项目简介

## 项目定位

Ragent AI 是一个基于 Java/Spring Boot 的企业级 Agentic RAG 平台。项目覆盖从知识文档入库、解析、切分、向量化、检索、重排，到对话问答、意图识别、MCP 工具调用、链路追踪和管理后台的完整闭环。

源码上体现为前后端分离架构：

- 后端：Maven 多模块 Java 项目，父项目 `ragent` 下包含 `bootstrap`、`framework`、`infra-ai`、`mcp-server`。
- 前端：`frontend` 下的 React + TypeScript + Vite 管理台和聊天界面。
- 配套资源：`resources/database` 提供 PostgreSQL/pgvector 表结构和初始化数据，`resources/docker` 提供 Milvus、RocketMQ 等部署编排。

## 解决什么问题

项目解决企业知识问答系统落地中的几个核心问题：

- 文档如何从本地、HTTP、S3、飞书等来源进入知识库。
- 文档如何解析、清洗、切分、增强、Embedding 并写入向量数据库。
- 用户问题如何结合历史记忆做改写、拆分和意图识别。
- 如何在多个知识库、多个检索通道、多个模型供应商之间编排。
- 如何把知识库检索和 MCP 工具调用融合进同一个回答链路。
- 如何处理模型不稳定、并发限流、流式输出、取消任务、链路追踪和管理后台。

## 目标用户

- 想学习企业级 RAG/Agent/MCP 工程实践的 Java 开发者。
- 需要构建内部知识库问答、智能客服、业务数据查询助手的研发团队。
- 需要通过项目学习 AI 应用架构、简历包装和面试表达的后端开发者。

## 核心功能

- 知识库管理：知识库、文档、Chunk、入库日志、定时刷新。
- 文档入库 Pipeline：Fetcher、Parser、Enhancer、Chunker、Enricher、Indexer 等节点化流程。
- RAG 对话：SSE 流式问答、历史记忆、摘要压缩、问题改写、意图识别、多路检索、重排、Prompt 编排。
- Agentic 能力：意图树驱动的 KB/MCP/SYSTEM 路由，MCP 工具参数抽取和调用。
- MCP 集成：主服务作为 MCP Client，`mcp-server` 独立暴露 Weather、Ticket、Sales 三类工具。
- 模型路由：封装 Chat、Embedding、Rerank，多供应商候选模型、优先级、熔断降级。
- 工程能力：Redis 公平排队限流、Redisson 信号量、RocketMQ 文档分块事件、全链路 Trace、Sa-Token 认证。

# 技术栈

| 类别 | 使用情况 | 判断依据 |
| --- | --- | --- |
| Java 版本 | Java 17 | 父 `pom.xml` 的 `<java.version>17</java.version>` |
| Spring Boot | 3.5.7 | 父 `pom.xml` 的 `spring-boot.version` |
| Spring Cloud | 未发现显式依赖 | 父/子 POM 未引入 Spring Cloud BOM 或 starter |
| 构建工具 | Maven 多模块 | 根 `pom.xml` packaging 为 `pom`，modules 包含 4 个后端模块 |
| 数据库 | PostgreSQL | `application.yaml` 配置 `org.postgresql.Driver` 和 `jdbc:postgresql://127.0.0.1:5432/ragent` |
| ORM | MyBatis-Plus | `framework` 引入 `mybatis-plus-spring-boot3-starter`，启动类 `@MapperScan` |
| 向量数据库 | pgvector 默认，Milvus 可选 | `rag.vector.type: pg`；POM 引入 Milvus SDK；存在 `PgVectorStoreService` 和 `MilvusVectorStoreService` |
| Redis | Spring Data Redis + Redisson | `framework` POM 引入 `spring-boot-starter-data-redis`、`redisson-spring-boot-starter` |
| MQ | RocketMQ | POM 引入 `rocketmq-spring-boot-starter`，配置 `rocketmq.name-server` |
| 对象存储 | S3/RustFS | `software.amazon.awssdk:s3`，配置 `rustfs.url` |
| 文档解析 | Apache Tika | `bootstrap` POM 引入 `tika-core` 和 `tika-parsers-standard-package` |
| AI 框架 | 自研轻量模型编排，不依赖 Spring AI/LangChain4j | `infra-ai` 中自定义 `LLMService`、`EmbeddingService`、`RerankService` |
| 模型供应商 | Ollama、阿里百炼、AIHubMix、SiliconFlow | `application.yaml` 的 `ai.providers` |
| MCP | Model Context Protocol Java SDK | POM 引入 `io.modelcontextprotocol.sdk:mcp` 和 `mcp-json-jackson2` |
| 认证 | Sa-Token | `framework` POM 引入 `sa-token-spring-boot3-starter` 和 Redis adapter |
| 前端 | React 18/TypeScript/Vite/Tailwind | `frontend/package.json`、`vite.config.ts`、`src/*.tsx` |

# 架构风格

## 模块化单体 + 独立 MCP 服务

主业务服务是模块化单体：`bootstrap` 聚合业务和启动入口，依赖 `framework` 和 `infra-ai`。`mcp-server` 是独立 Spring Boot 应用，通过 HTTP Streamable MCP 暴露工具。

判断依据：

- 根 POM 只有 4 个 Maven 模块，没有 Spring Cloud 服务注册、网关、配置中心等微服务基础设施。
- 主启动类是 `bootstrap/src/main/java/com/nageoffer/ai/ragent/RagentApplication.java`。
- MCP 服务有独立启动类 `mcp-server/src/main/java/com/nageoffer/ai/ragent/mcp/McpServerApplication.java`，端口为 9099。

## 分层架构

后端明显采用分层架构：

- Controller：`rag/controller`、`knowledge/controller`、`ingestion/controller`、`user/controller`。
- Service：`*/service` 和 `*/service/impl`。
- DAO：`*/dao/entity`、`*/dao/mapper`。
- Core：`rag/core`、`core/chunk`、`core/parser` 放置领域算法和编排。
- Config/AOP/Trace：配置、横切和链路追踪独立。

## DDD/领域分包倾向

项目不是严格 DDD，但有领域分包倾向：

- `rag`：对话、检索、意图、记忆、Prompt、MCP。
- `knowledge`：知识库、文档、Chunk、定时刷新。
- `ingestion`：入库 Pipeline、节点、任务、节点日志。
- `user`：认证、用户、角色。
- `admin`：后台统计。

## 六边形架构倾向

项目具备端口-适配器思想，但不是严格六边形：

- `infra-ai` 用 `ChatClient`、`EmbeddingClient`、`RerankClient` 屏蔽供应商差异。
- `VectorStoreService`、`VectorStoreAdmin` 屏蔽 pgvector/Milvus 差异。
- `McpToolExecutor` 屏蔽本地工具和远程 MCP Tool 的执行差异。

## Agentic RAG 架构

项目的 Agent 不是 LangChain 式独立 Agent 类，而是由 `StreamChatPipeline`、`IntentResolver`、`RetrievalEngine`、`McpToolRegistry`、`RAGPromptService` 共同形成的 Agentic RAG 编排。

判断依据：

- 问题先经过 Memory、Rewrite、Intent，再决定 KB、MCP 或 SYSTEM 路径。
- MCP 参数由 LLM 抽取，工具结果再作为上下文参与最终生成。
- KB 检索和 MCP 工具可在同一回答链路中混合。
