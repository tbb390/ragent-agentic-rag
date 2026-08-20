 # Ragent 项目知识库

本目录是对当前项目源码的长期可复用分析文档。

# 推荐阅读顺序

1. [项目全景分析](project-overview.md)
2. [模块分析](module-analysis.md)
3. [项目目录树](project-tree.md)
4. [启动流程分析](startup-analysis.md)
5. [请求调用链分析](request-flow.md)
6. [Agent 架构分析](agent-architecture.md)
7. [RAG 架构分析](rag-architecture.md)
8. [MCP 架构分析](mcp-analysis.md)
9. [数据库分析](database-analysis.md)
10. [Redis 分析](redis-analysis.md)
11. [配置中心分析](config-analysis.md)
12. [源码阅读路线](reading-roadmap.md)
13. [架构图总览](architecture-summary.md)
14. [简历与面试价值](interview-notes.md)
15. [完整项目简历](project-resume.md)

# 文档清单

| 文档 | 内容 |
| --- | --- |
| `project-overview.md` | 项目定位、技术栈、架构风格 |
| `module-analysis.md` | Maven 模块和业务包职责 |
| `project-tree.md` | 重要源码目录树 |
| `startup-analysis.md` | Spring Boot 启动、Bean、配置、MCP 初始化 |
| `request-flow.md` | Controller 到 Service、Repository、数据库调用链 |
| `agent-architecture.md` | Agent 入口、Prompt、Memory、Tool、生命周期 |
| `rag-architecture.md` | 文档入库和 RAG 查询完整链路 |
| `mcp-analysis.md` | MCP Server、Tool 注册、发现、调用和新增方式 |
| `database-analysis.md` | 数据库、ORM、Mapper、Entity、业务模型 |
| `redis-analysis.md` | Redis key、缓存、锁、限流、取消、Session |
| `config-analysis.md` | application 配置和 profile 缺失情况 |
| `reading-roadmap.md` | 7 天源码阅读路线 |
| `architecture-summary.md` | Mermaid 架构图总览 |
| `interview-notes.md` | 简历亮点、面试问题、架构表达 |
| `project-resume.md` | 可直接用于简历的完整项目经历、精简版与面试口径 |

# 扫描统计

- 后端 Maven 模块：4 个
  - `bootstrap`
  - `framework`
  - `infra-ai`
  - `mcp-server`
- 前端应用目录：1 个
  - `frontend`
- 实际扫描 Java 文件：464 个
- 主源码 Java 文件：451 个
- 重点分析模块/业务包：`bootstrap/admin`、`bootstrap/core`、`bootstrap/ingestion`、`bootstrap/knowledge`、`bootstrap/rag`、`bootstrap/user`、`framework`、`infra-ai`、`mcp-server`

# 快速定位

- 主启动类：`bootstrap/src/main/java/com/nageoffer/ai/ragent/RagentApplication.java`
- MCP 启动类：`mcp-server/src/main/java/com/nageoffer/ai/ragent/mcp/McpServerApplication.java`
- RAG 入口：`bootstrap/src/main/java/com/nageoffer/ai/ragent/rag/controller/RAGChatController.java`
- RAG 流水线：`bootstrap/src/main/java/com/nageoffer/ai/ragent/rag/service/pipeline/StreamChatPipeline.java`
- 检索引擎：`bootstrap/src/main/java/com/nageoffer/ai/ragent/rag/core/retrieve/RetrievalEngine.java`
- 多路检索：`bootstrap/src/main/java/com/nageoffer/ai/ragent/rag/core/retrieve/MultiChannelRetrievalEngine.java`
- 入库引擎：`bootstrap/src/main/java/com/nageoffer/ai/ragent/ingestion/engine/IngestionEngine.java`
- MCP Client：`bootstrap/src/main/java/com/nageoffer/ai/ragent/rag/core/mcp/McpClientAutoConfiguration.java`
- MCP Server 配置：`mcp-server/src/main/java/com/nageoffer/ai/ragent/mcp/config/McpServerConfig.java`
- 数据库脚本：`resources/database/schema_pg.sql`
