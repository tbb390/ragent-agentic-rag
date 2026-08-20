/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.nageoffer.ai.ragent.infra.embedding;

import com.nageoffer.ai.ragent.infra.model.ModelTarget;
import okhttp3.OkHttpClient;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.stream.IntStream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class EmbeddingBatchConcurrencyBenchmarkTest {

    private static final int TEXT_COUNT = 32;
    private static final int BATCH_SIZE = 8;
    private static final long REMOTE_LATENCY_MS = 120;
    private static final int RUNS = 5;

    @Test
    void boundedConcurrencyShouldReduceEmbeddingWallClockTimeAndPreserveOrder() {
        List<String> texts = IntStream.range(0, TEXT_COUNT).mapToObj(String::valueOf).toList();

        DelayedEmbeddingClient sequentialClient = new DelayedEmbeddingClient(1);
        DelayedEmbeddingClient parallelClient = new DelayedEmbeddingClient(4);
        measure(sequentialClient, texts);
        measure(parallelClient, texts);

        List<BenchmarkResult> sequentialRuns = IntStream.range(0, RUNS)
                .mapToObj(ignored -> measure(sequentialClient, texts))
                .toList();
        List<BenchmarkResult> parallelRuns = IntStream.range(0, RUNS)
                .mapToObj(ignored -> measure(parallelClient, texts))
                .toList();
        long sequentialAvg = averageDuration(sequentialRuns);
        long parallelAvg = averageDuration(parallelRuns);
        double speedup = (double) sequentialAvg / parallelAvg;

        assertEquals(sequentialRuns.get(0).vectors(), parallelRuns.get(0).vectors());
        assertEquals(TEXT_COUNT, parallelRuns.get(0).vectors().size());
        assertTrue(speedup >= 2.0, () -> "Expected at least 2x speedup, actual: " + speedup);

        System.out.printf(
                "Embedding batch benchmark: runs=%d, texts=%d, batch=%d, latency=%dms, sequentialAvg=%dms, parallelAvg=%dms, reduction=%.2f%%, speedup=%.2fx%n",
                RUNS, TEXT_COUNT, BATCH_SIZE, REMOTE_LATENCY_MS, sequentialAvg, parallelAvg,
                (1.0 - (double) parallelAvg / sequentialAvg) * 100, speedup);
    }

    private long averageDuration(List<BenchmarkResult> results) {
        return Math.round(results.stream().mapToLong(BenchmarkResult::durationMs).average().orElseThrow());
    }

    private BenchmarkResult measure(DelayedEmbeddingClient client, List<String> texts) {
        long start = System.nanoTime();
        List<List<Float>> vectors = client.embedBatch(texts, null);
        long durationMs = TimeUnit.NANOSECONDS.toMillis(System.nanoTime() - start);
        return new BenchmarkResult(durationMs, vectors);
    }

    private record BenchmarkResult(long durationMs, List<List<Float>> vectors) {
    }

    private static final class DelayedEmbeddingClient extends AbstractOpenAIStyleEmbeddingClient {

        private final int concurrency;

        private DelayedEmbeddingClient(int concurrency) {
            super(new OkHttpClient());
            this.concurrency = concurrency;
        }

        @Override
        public String provider() {
            return "benchmark";
        }

        @Override
        protected int maxBatchSize() {
            return BATCH_SIZE;
        }

        @Override
        protected int maxBatchConcurrency() {
            return concurrency;
        }

        @Override
        protected List<List<Float>> doEmbed(List<String> texts, ModelTarget target) {
            try {
                Thread.sleep(REMOTE_LATENCY_MS);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new IllegalStateException(e);
            }
            return texts.stream().map(text -> List.of(Float.parseFloat(text))).toList();
        }
    }
}
