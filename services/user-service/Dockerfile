FROM rust:1.100-bookworm AS builder
WORKDIR /app
ENV CARGO_INCREMENTAL=0
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --release --locked && \
    cp /app/target/release/user-service /usr/local/bin/user-service

FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --uid 10001 --user-group --shell /usr/sbin/nologin appuser
COPY --from=builder --chown=10001:10001 /usr/local/bin/user-service /usr/local/bin/user-service
ENV ROCKET_ADDRESS=0.0.0.0 \
    ROCKET_PORT=8000
EXPOSE 8000
USER 10001:10001
ENTRYPOINT ["user-service"]
