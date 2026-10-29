# Koru

[Koru](https://korulang.org) is a compiled systems language that lowers to Zig.
The compiler and standard library are vendored into each framework directory's
Docker build context (see `orisha/vendor/koru`), so the entry is
self-contained.

## Frameworks

* [orisha](orisha/) — io_uring web framework written in Koru, with a native
  PostgreSQL wire driver.
