# 配置中心分析

# 配置文件

主服务配置：

```text
bootstrap/src/main/resources/application.yaml
```

MCP Server 配置：

```text
mcp-server/src/main/resources/application.yml
```

未发现：

- `bootstrap.yml`
- `bootstrap.yaml`
- `application-dev.yml`
- `application-test.yml`
- `application-prod.yml`
- `application-dev.yaml`
- `application-test.yaml`
- `application-prod.yaml`

因此项目当前没有外部配置中心，也没有显式 profile 分层配置。

# application.yaml 核心配置

## 服务配置

```yaml
server:
  port: 9090
  servlet:
    context-path: /api/ragent
```

## 数据源

```yaml
spring:
  datasource:
    driver-class-name: org.postgresql.Driver
    username: postgres
    password: postgres
    url: jdbc:postgresql://127.0.0.1:5432/ragent?client_encoding=UTF8
```

## Redis

```yaml
spring:
  data:
    redis:
      host: 127.0.0.1
      port: 6379
      password: 123456
```

## RocketMQ

```yaml
rocketmq:
  name-server: 127.0.0.1:9876
  producer:
    group: ragent-producer${unique-name:}_pg
```

## 向量数据库

```yaml
milvus:
  uri: http://localhost:19530

rag:
  vector:
    type: pg
```

## RAG 默认配置

```yaml
rag:
  default:
    collection-name: rag_default_store
    dimension: 1536
    metric-type: COSINE
    sse-timeout-ms: 300000
```

## 记忆配置

```yaml
rag:
  memory:
    history-keep-turns: 4
    summary-start-turns: 5
    summary-enabled: true
    summary-max-chars: 200
    title-max-length: 30
```

## MCP 配置

```yaml
rag:
  mcp:
    servers:
      - name: default
        url: http://localhost:9099
```

## AI 配置

供应商：

- Ollama
- Bailian
- AIHubMix
- SiliconFlow

模型类型：

- Chat
- Embedding
- Rerank

API Key 使用环境变量：

- `${BAILIAN_API_KEY:}`
- `${AIHUBMIX_API_KEY:}`
- `${SILICONFLOW_API_KEY:}`

# MCP Server application.yml

```yaml
server:
  port: 9099

spring:
  application:
    name: ragent-mcp-server
```

# profile 配置

## dev

未发现独立 dev 配置。

当前 `application.yaml` 实际更接近本地开发环境：

- PostgreSQL：`127.0.0.1:5432`
- Redis：`127.0.0.1:6379`
- RocketMQ：`127.0.0.1:9876`
- Milvus：`localhost:19530`
- RustFS：`localhost:9000`
- Ollama：`localhost:11434`

## test

未发现独立 test 配置。

建议未来拆分：

- 使用独立数据库 schema。
- 关闭真实模型调用或使用 mock/noop。
- 降低并发限流阈值。
- RocketMQ 可替换为测试容器或禁用。

## prod

未发现独立 prod 配置。

建议未来拆分：

- 数据库、Redis、MQ、对象存储、Milvus 地址全部环境变量化。
- API Key 统一从环境变量或密钥管理系统读取。
- 打开更严格日志采样和 Trace 存储策略。
- `app.demo-mode` 按环境控制。
- 限流、超时、线程池参数按生产容量配置。

# 配置绑定类

| 配置前缀 | 类 |
| --- | --- |
| `ai` | `AIModelProperties` |
| `rag.default` | `RAGDefaultProperties` |
| `rag.memory` | `MemoryProperties` |
| `rag.rate-limit` | `RAGRateLimitProperties` |
| `rag.search` | `SearchChannelProperties` |
| `rag.trace` | `RagTraceProperties` |
| `rag.mcp` | `McpClientProperties` |
| `rag.semaphore` | `RagSemaphoreProperties` |
| `rag.knowledge.schedule` | `KnowledgeScheduleProperties` |
| `app.demo-mode` | `DemoModeProperties` |
| `app.eval` | `EvalProperties` |

# 配置风险

- 当前数据库、Redis、RocketMQ 密码和地址写在默认配置中，生产应改为环境变量。
- 未拆分 profile，容易把本地配置带到生产。
- `rag.vector.type` 默认 pg，但同时存在 Milvus 配置，部署文档需要明确二选一。
- README 内容存在编码显示问题，不影响代码运行，但影响文档可读性。
