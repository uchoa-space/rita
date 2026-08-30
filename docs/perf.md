# Performance ledger (ADR 013)

Every performance change, kept or reverted. Read before proposing one.

| Date | Idea | Baseline → Result | Verdict | Why |
|---|---|---|---|---|
| 2026-08-30 | HNSW index on `chunks.embedding` | seq scan + top-N sort, ~3 ms over 2,561 chunks | not attempted | plan under 50 ms; index would cost recall and buy nothing |
