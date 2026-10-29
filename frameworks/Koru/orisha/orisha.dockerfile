# syntax=docker/dockerfile:1.7
# Orisha (Koru) TechEmpower entry — self-contained: the Koru toolchain
# and the Orisha framework are vendored under vendor/.
FROM ubuntu:24.04 AS build
ARG ZIG_VERSION=0.15.2
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git xz-utils pkg-config libssl-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
RUN set -eu; \
    case "$(dpkg --print-architecture)" in \
        amd64) ZIG_ARCH=x86_64 ;; \
        arm64) ZIG_ARCH=aarch64 ;; \
        *) echo "unsupported arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://ziglang.org/download/${ZIG_VERSION}/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}.tar.xz" \
        | tar -xJ -C /opt; \
    ln -sf "/opt/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}/zig" /usr/local/bin/zig

WORKDIR /src
COPY . /src/app
WORKDIR /src/app
RUN mkdir -p /out /usr/local \
    && rm -rf /usr/local/src /usr/local/koru_std \
    && ln -sfn /src/app/vendor/koru/src /usr/local/src \
    && ln -sfn /src/app/vendor/koru/koru_std /usr/local/koru_std \
    && test -f /usr/local/src/ast.zig \
    && cd /src/app/vendor/koru && zig build \
    && install -m755 zig-out/bin/koruc /usr/local/bin/koruc \
    && cd /src/app \
    && koruc main.k --release=fast --build=race \
    && install -m755 a.out /out/orisha-techempower

FROM ubuntu:24.04
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates libssl3 zlib1g \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /out/orisha-techempower /orisha-techempower
EXPOSE 8080
ENTRYPOINT ["/orisha-techempower"]
