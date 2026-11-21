FROM lukemathwalker/cargo-chef:0.1.78-rust-1.100-slim-bookworm AS chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo chef cook --release
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --locked --release --bin user-service && \
    cp target/release/user-service /user-service

FROM gcr.io/distroless/cc-debian12:nonroot AS runtime
WORKDIR /app
COPY --from=builder --chmod=500 --chown=65532:65532 /user-service /app/user-service
EXPOSE 8000
ENV ROCKET_ADDRESS=0.0.0.0 \
    ROCKET_PORT=8000
ENTRYPOINT ["/app/user-service"]
