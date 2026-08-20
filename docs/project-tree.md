# 项目目录树

忽略 `.git`、`.idea`、`target`、`node_modules`、`dist`、`build`，保留重要源码结构。

```text
.
├── README.md
├── pom.xml
├── mvnw
├── mvnw.cmd
├── assets
│   ├── ragent-ai-banner.png
│   ├── ragent-framework.png
│   ├── ragent-chain-v3.png
│   ├── multi-channel-retrieval.png
│   ├── model-routing-failover.svg
│   ├── model-health-store.svg
│   └── ingestion-pipeline.png
├── bootstrap
│   ├── pom.xml
│   └── src
│       ├── main
│       │   ├── java/com/nageoffer/ai/ragent
│       │   │   ├── RagentApplication.java
│       │   │   ├── admin
│       │   │   │   ├── controller
│       │   │   │   └── service
│       │   │   ├── core
│       │   │   │   ├── chunk
│       │   │   │   │   └── strategy
│       │   │   │   └── parser
│       │   │   ├── ingestion
│       │   │   │   ├── controller
│       │   │   │   ├── dao
│       │   │   │   │   ├── entity
│       │   │   │   │   └── mapper
│       │   │   │   ├── domain
│       │   │   │   │   ├── context
│       │   │   │   │   ├── enums
│       │   │   │   │   ├── pipeline
│       │   │   │   │   ├── result
│       │   │   │   │   └── settings
│       │   │   │   ├── engine
│       │   │   │   ├── node
│       │   │   │   ├── prompt
│       │   │   │   ├── service
│       │   │   │   ├── strategy/fetcher
│       │   │   │   └── util
│       │   │   ├── knowledge
│       │   │   │   ├── config
│       │   │   │   ├── controller
│       │   │   │   ├── dao
│       │   │   │   │   ├── entity
│       │   │   │   │   ├── handler
│       │   │   │   │   └── mapper
│       │   │   │   ├── enums
│       │   │   │   ├── filter
│       │   │   │   ├── handler
│       │   │   │   ├── mq
│       │   │   │   ├── schedule
│       │   │   │   └── service
│       │   │   ├── rag
│       │   │   │   ├── aop
│       │   │   │   ├── config
│       │   │   │   ├── constant
│       │   │   │   ├── controller
│       │   │   │   ├── core
│       │   │   │   │   ├── guidance
│       │   │   │   │   ├── intent
│       │   │   │   │   ├── mcp
│       │   │   │   │   ├── memory
│       │   │   │   │   ├── prompt
│       │   │   │   │   ├── retrieve
│       │   │   │   │   │   ├── channel
│       │   │   │   │   │   └── postprocessor
│       │   │   │   │   ├── rewrite
│       │   │   │   │   └── vector
│       │   │   │   ├── dao
│       │   │   │   │   ├── entity
│       │   │   │   │   └── mapper
│       │   │   │   ├── dto
│       │   │   │   ├── enums
│       │   │   │   ├── eval
│       │   │   │   ├── mq
│       │   │   │   ├── service
│       │   │   │   │   ├── handler
│       │   │   │   │   ├── impl
│       │   │   │   │   ├── pipeline
│       │   │   │   │   └── ratelimit
│       │   │   │   ├── trace
│       │   │   │   └── util
│       │   │   └── user
│       │   │       ├── config
│       │   │       ├── controller
│       │   │       ├── dao
│       │   │       ├── enums
│       │   │       └── service
│       │   └── resources
│       │       ├── application.yaml
│       │       ├── lua/queue_claim_atomic.lua
│       │       ├── META-INF/additional-spring-configuration-metadata.json
│       │       └── prompt
│       │           ├── answer-chat-kb.st
│       │           ├── answer-chat-mcp.st
│       │           ├── answer-chat-mcp-kb-mixed.st
│       │           ├── answer-chat-system.st
│       │           ├── context-format.st
│       │           ├── conversation-summary.st
│       │           ├── conversation-title.st
│       │           ├── guidance-ambiguity-check.st
│       │           ├── guidance-prompt.st
│       │           ├── intent-classifier.st
│       │           ├── mcp-parameter-extract.st
│       │           ├── mcp-parameter-extract-user.st
│       │           ├── pdf-format-guard.st
│       │           └── user-question-rewrite.st
│       └── test/java/com/nageoffer/ai/ragent
├── framework
│   ├── pom.xml
│   └── src/main
│       ├── java/com/nageoffer/ai/ragent/framework
│       │   ├── cache
│       │   ├── config
│       │   ├── context
│       │   ├── convention
│       │   ├── database
│       │   ├── distributedid
│       │   ├── errorcode
│       │   ├── exception
│       │   ├── idempotent
│       │   ├── mq
│       │   ├── trace
│       │   └── web
│       └── resources/lua/snowflake_init.lua
├── infra-ai
│   ├── pom.xml
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
│   ├── pom.xml
│   └── src/main
│       ├── java/com/nageoffer/ai/ragent/mcp
│       │   ├── McpServerApplication.java
│       │   ├── config/McpServerConfig.java
│       │   └── executor
│       │       ├── SalesMcpExecutor.java
│       │       ├── TicketMcpExecutor.java
│       │       └── WeatherMcpExecutor.java
│       └── resources/application.yml
├── frontend
│   ├── package.json
│   ├── vite.config.ts
│   └── src
│       ├── App.tsx
│       ├── main.tsx
│       ├── router.tsx
│       ├── components
│       ├── hooks
│       ├── pages
│       ├── services
│       ├── stores
│       ├── styles
│       ├── types
│       └── utils
├── resources
│   ├── database
│   │   ├── schema_pg.sql
│   │   ├── init_data_pg.sql
│   │   ├── upgrade_v1.0_to_v1.1.sql
│   │   └── upgrade_v1.1_to_v1.2.sql
│   ├── docker
│   └── docs/knowledge
├── scripts
│   └── sse_queue_test.sh
└── docs
    └── *.md
```
