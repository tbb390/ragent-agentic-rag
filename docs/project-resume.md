项目经历
Ragent AI 企业级 Agentic RAG 平台
开源项目部署、源码分析与性能优化测试实践
技术栈：Java 17 / Spring Boot 3 / Docker / Redis / PostgreSQL / pgvector / RocketMQ / RustFS / SSE / RAG / LLM / SiliconFlow / 向量检索
项目简介：基于 Spring Boot 3 构建的企业级 RAG 应用系统，实现知识库管理、文档上传、异步分块、Embedding 向量化入库、检索增强生成及大模型流式输出的完整链路。
项目实践：
· 基于 Docker 完成 Redis、PostgreSQL、RocketMQ、RustFS 等依赖服务部署与联调，搭建本地企业知识库问答环境，打通文件存储、消息消费、向量入库与检索问答链路。
· 排查文档分块任务长期 Running 后 Failed 的问题，结合 RocketMQ 消息状态、消费者日志与容器启动参数定位 JVM 配置异常；修复后分块任务成功率恢复至 100%，消息积压由 12 降至 0。
· 创新优化大文档 Embedding 批处理功能，针对请求超过供应商单批上限后串行执行的性能瓶颈，实现固定大小分批、4 路有界并发、按索引保序归并及异常批次快速取消；预热后 5 轮 A/B 基准中，平均耗时由 510ms 降至 136ms，降低约 73%，吞吐提升 3.75 倍。
· 构建 50 份 Markdown 文档、150 条标准评测问题的测试数据集，使用 SiliconFlow Qwen3-Embedding-8B 完成真实异步入库，累计处理 96,368 Bytes 文档数据并生成 2,450 个向量块，处理成功率 100%；Embedding P50/P95 分别为 16.96s/27.86s，端到端 P95 为 28.04s。
· 重构 RocketMQ 分块任务状态链路，使用统一任务 ID 串联消息生产、消费与执行阶段，并增加成功任务幂等判断，解决消息未消费时无任务记录及重复投递导致向量重复写入的问题。
· 完成 16 条向量检索自测，Top-1 / Top-3 向量自检召回率均为 100%，MRR 为 1.0000；空分块率、重复分块率均为 0%，向量维度与元数据完整率均为 100%，无孤儿分块及孤儿向量记录。
· 梳理 Retrieval → Rerank → Prompt Assembly → LLM Generation → SSE Streaming 核心链路，理解多路召回、重排序、Prompt 组装及 Token 级 SSE 流式输出的工程实现。
