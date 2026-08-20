# 数据库分析

# 使用哪些数据库

## PostgreSQL

主数据库：

```yaml
spring:
  datasource:
    driver-class-name: org.postgresql.Driver
    url: jdbc:postgresql://127.0.0.1:5432/ragent?client_encoding=UTF8
```

用途：

- 用户、会话、消息、反馈。
- 知识库、文档、Chunk、入库日志。
- 意图树、术语映射。
- RAG Trace。
- 入库 Pipeline 和任务。
- pgvector 向量存储。

## pgvector

启用：

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

向量表：

```text
t_knowledge_vector
```

用途：

- 保存 Chunk 内容、metadata、embedding。
- HNSW 索引用于相似度检索。

## Milvus

可选向量数据库：

```yaml
milvus:
  uri: http://localhost:19530
rag:
  vector:
    type: pg  # 可选 milvus / pg
```

实现类：

- `MilvusVectorStoreService`
- `MilvusVectorStoreAdmin`
- `MilvusRetrieverService`

# ORM 框架

使用 MyBatis-Plus。

依据：

- POM 引入 `mybatis-plus-spring-boot3-starter`。
- 启动类使用 `@MapperScan`。
- Mapper 继承 `BaseMapper<T>`。
- `DataBaseConfiguration` 配置 `MybatisPlusInterceptor` 和 `PaginationInnerInterceptor(DbType.POSTGRE_SQL)`。

# Mapper 位置

```text
bootstrap/src/main/java/com/nageoffer/ai/ragent/user/dao/mapper
bootstrap/src/main/java/com/nageoffer/ai/ragent/rag/dao/mapper
bootstrap/src/main/java/com/nageoffer/ai/ragent/knowledge/dao/mapper
bootstrap/src/main/java/com/nageoffer/ai/ragent/ingestion/dao/mapper
```

Mapper 数量按业务域：

- user：`UserMapper`
- rag：Conversation、Message、Summary、Feedback、Intent、SampleQuestion、Trace、QueryTermMapping
- knowledge：KnowledgeBase、Document、Chunk、ChunkLog、Schedule、ScheduleExec
- ingestion：Pipeline、PipelineNode、Task、TaskNode

# Entity 位置

```text
bootstrap/src/main/java/com/nageoffer/ai/ragent/user/dao/entity
bootstrap/src/main/java/com/nageoffer/ai/ragent/rag/dao/entity
bootstrap/src/main/java/com/nageoffer/ai/ragent/knowledge/dao/entity
bootstrap/src/main/java/com/nageoffer/ai/ragent/ingestion/dao/entity
```

实体类使用 `@TableName` 映射表名。

# 表结构来源

主表结构：

```text
resources/database/schema_pg.sql
```

初始化数据：

```text
resources/database/init_data_pg.sql
```

升级脚本：

```text
resources/database/upgrade_v1.0_to_v1.1.sql
resources/database/upgrade_v1.1_to_v1.2.sql
```

# 表清单

从 `schema_pg.sql` 扫描到 20 张核心表：

| 表 | 业务含义 |
| --- | --- |
| `t_user` | 用户账号、角色、登录相关信息 |
| `t_conversation` | 会话主表 |
| `t_conversation_summary` | 会话摘要 |
| `t_message` | 用户/助手消息 |
| `t_message_feedback` | 回答点赞/点踩反馈 |
| `t_sample_question` | 样例问题 |
| `t_knowledge_base` | 知识库 |
| `t_knowledge_document` | 知识文档 |
| `t_knowledge_chunk` | 文档 Chunk |
| `t_knowledge_document_chunk_log` | 文档切分/入库日志 |
| `t_knowledge_document_schedule` | 文档定时刷新配置 |
| `t_knowledge_document_schedule_exec` | 定时刷新执行记录 |
| `t_intent_node` | 意图树节点 |
| `t_query_term_mapping` | 查询术语映射 |
| `t_rag_trace_run` | RAG Trace 一次运行 |
| `t_rag_trace_node` | RAG Trace 节点 |
| `t_ingestion_pipeline` | 入库 Pipeline |
| `t_ingestion_pipeline_node` | 入库 Pipeline 节点 |
| `t_ingestion_task` | 入库任务 |
| `t_ingestion_task_node` | 入库任务节点执行记录 |
| `t_knowledge_vector` | pgvector 向量表 |

# 业务模型推导

## 用户模型

- 用户表 `t_user`。
- 认证使用 Sa-Token。
- 用户上下文通过 `UserContextInterceptor` 写入 `UserContext`。

## 会话模型

- `t_conversation` 记录会话标题、用户、最后更新时间。
- `t_message` 记录 user/assistant 消息。
- `t_conversation_summary` 保存压缩摘要。
- `t_message_feedback` 记录用户对回答的反馈。

## 知识库模型

- `t_knowledge_base` 是知识库。
- `t_knowledge_document` 是知识库内文档。
- `t_knowledge_chunk` 是文档切分后的文本块元数据。
- `t_knowledge_vector` 是实际向量索引表。
- `collection_name` 将知识库与向量空间关联。

## 入库 Pipeline 模型

- `t_ingestion_pipeline` 定义 Pipeline。
- `t_ingestion_pipeline_node` 定义节点类型、顺序、配置和条件。
- `t_ingestion_task` 是一次执行任务。
- `t_ingestion_task_node` 是每个节点的执行记录。

## 意图模型

- `t_intent_node` 构建树形意图。
- 节点可区分 KB、MCP、SYSTEM。
- KB 节点可绑定知识库/collection。
- MCP 节点可绑定 `mcp_tool_id` 和参数抽取 Prompt。

## Trace 模型

- `t_rag_trace_run` 记录一次 RAG 请求。
- `t_rag_trace_node` 记录流水线节点，如 rewrite、intent、retrieve、LLM 首包等。
