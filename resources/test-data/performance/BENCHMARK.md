# RAG Ingestion Performance Report

## Dataset

- 50 generated Markdown documents across five business domains
- 150 evaluation questions with expected answers and document IDs
- 96,368 bytes of source documents
- Fixed-size chunking: 48 characters with 8-character overlap

## Controlled A/B Benchmark

The benchmark isolates remote-call latency so that sequential and bounded-concurrent batching run under the same conditions.

| Metric | Sequential | 4-way bounded concurrency |
| --- | ---: | ---: |
| Runs after warm-up | 5 | 5 |
| Texts per run | 32 | 32 |
| Batch size | 8 | 8 |
| Simulated latency per request | 120 ms | 120 ms |
| Average wall-clock time | 510 ms | 136 ms |
| Time reduction | - | 73.33% |
| Throughput speedup | 1.00x | 3.75x |

Vector count and source-order consistency assertions passed.

## Real Ingestion Validation

Environment: SiliconFlow `Qwen/Qwen3-Embedding-8B`, RocketMQ 5.2, RustFS, PostgreSQL with pgvector.

| Metric | Result |
| --- | ---: |
| Documents | 50 |
| Successful documents | 50 (100%) |
| Vector chunks | 2,450 |
| Embedding average | 15,103 ms |
| Embedding P50 | 16,963 ms |
| Embedding P95 | 27,861 ms |
| Embedding min / max | 368 / 50,424 ms |
| End-to-end average | 15,362 ms |
| End-to-end P95 | 28,038 ms |
| Effective embedding throughput | 3.24 chunks/s |

The real-provider run validates correctness and stability under substantial external-service latency variance. It is not a before/after comparison; improvement percentages come only from the controlled A/B benchmark.

## Retrieval Smoke Test

One query completed successfully in 14,462 ms and retrieved the expected document at rank 10. This confirms the end-to-end retrieval path but also establishes a weak-ranking baseline for future reranking or hybrid-retrieval work.
