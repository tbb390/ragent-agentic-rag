# Ragent-Agentic-RAG

基于大语言模型（LLM）的企业级 Agentic RAG 应用平台。

本项目围绕知识库问答、智能检索、模型调用、工具编排等核心能力，
实现了从文档解析、向量化检索到大模型生成回复的完整应用链路。

项目过程中结合实际运行与工程实践，对系统架构、检索流程以及 AI 应用链路进行了深入学习和优化。

---

## ✨ 项目介绍

Ragent-Agentic-RAG 是一个面向企业知识管理场景的智能问答系统。

通过结合：

- 大语言模型（LLM）
- Retrieval-Augmented Generation（RAG）
- Embedding 向量检索
- Agent 工具调用
- MCP 协议
- SSE 流式响应

实现基于企业知识库的智能检索与问答能力。

用户可以上传业务文档，系统自动完成文档解析、文本切分、向量化处理，
并结合检索结果生成更加准确的回答。

---

## 🏗️ 系统架构

整体流程：

用户请求
↓
Query 理解与处理
↓
知识库检索
↓
向量召回 / 重排序
↓
Prompt 构建
↓
LLM 推理
↓
流式返回结果


主要模块：

- 文档处理模块
    - 文件解析
    - 文本切分
    - Embedding 向量生成

- 检索增强模块
    - 向量检索
    - 多路召回
    - Rerank 重排序

- Agent 能力模块
    - 工具调用
    - MCP 服务接入
    - 上下文管理

- 服务模块
    - Spring Boot 后端
    - React 前端
    - SSE 流式通信

---

## 🔧 技术栈

### Backend

- Java 17
- Spring Boot 3
- Maven
- Redis
- PostgreSQL + pgvector
- RocketMQ
- SSE


### AI Application

- LLM API 调用
- Prompt Engineering
- RAG Pipeline
- Embedding
- Rerank
- Agent Workflow
- MCP


### Frontend

- React
- TypeScript


### Infrastructure

- Docker
- Ollama
- RustFS

---

## 🚀 核心功能

### 1. 企业知识库问答

支持：

- 文档上传
- 自动解析
- Chunk 切分
- 向量化存储
- 基于知识库回答


### 2. Agent 检索增强流程

支持：

- 查询理解
- 多阶段检索
- 上下文构建
- 大模型生成


### 3. 模型能力扩展

支持多模型接入：

- 本地模型
- 云端大模型 API
- Embedding 模型


### 4. MCP 工具调用

支持通过 MCP 协议扩展外部工具能力，
实现 Agent 与外部服务之间的协作。

---

## 📈 工程实践

在项目运行和调试过程中，针对 AI 应用链路进行了工程优化：

### Embedding Pipeline 优化

针对批量文档处理流程：

- 增加批量处理能力
- 引入并发执行
- 优化任务调度方式
- 保证结果顺序一致性

提升知识库构建效率。


### 检索流程优化

完善：

- 查询重写
- 多路检索
- Rerank 重排序
- 检索参数配置

提升复杂问题场景下的回答质量。


### 项目分析文档

补充：

- 系统架构分析
- RAG 流程分析
- Agent 调用链路分析
- 模块结构说明
- 性能测试记录

---

## 📂 项目结构
ragent-agentic-rag
├── bootstrap      # 应用启动模块
├── framework      # 核心框架能力
├── infra-ai       # AI基础设施
├── mcp-server     # MCP服务
├── frontend       # 前端应用
├── resources      # 配置及资源文件
└── docs           # 项目分析文档

---

## 📌 说明

本项目用于学习和实践企业级 Agent 应用开发流程，
重点探索大模型应用开发中的：

- RAG 系统设计
- Agent 工作流
- 模型调用管理
- 知识库构建
- AI 应用工程化实践
