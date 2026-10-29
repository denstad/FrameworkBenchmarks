# orisha Benchmarking Test

This is the [Orisha](https://korulang.org) portion of a [benchmarking test suite](https://github.com/TechEmpower/FrameworkBenchmarks) comparing a variety of web development platforms.

Orisha is a web framework written in [Koru](https://github.com/korulang/koru), a compiled systems language that lowers to Zig. The server is an io_uring pump with suspend/resume request handling; the PostgreSQL path is a native pgwire driver (extended query protocol, SCRAM-SHA-256 auth) with a per-worker connection pool that coalesces parked queries into shared flushes. No external web or database libraries are used.

### Test Type Implementation Source Code

* [Application routes](main.k) — router wiring for all seven test URLs
* [Handlers](handlers.k) — plaintext and JSON are pre-baked wire responses; the database tests are driven by the pump's suspend/resume path
* [Pump](vendor/orisha/lib/pump.kz) — io_uring event loop, request dispatch, pgwaiter machinery

## Test URLs

### PLAINTEXT

http://localhost:8080/plaintext

### JSON

http://localhost:8080/json

### Single Database Query

http://localhost:8080/db

### Multiple Database Queries

http://localhost:8080/queries?queries=

### Cached World Reads

http://localhost:8080/cached-worlds?queries=

### Fortune

http://localhost:8080/fortunes

### Database Updates

http://localhost:8080/updates?queries=
