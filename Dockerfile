FROM lukemathwalker/cargo-chef:0.1.78-rust-1.100-slim-bookworm AS chef
WORKDIR /app

FROM chef AS planner
COPY --parents **/Cargo.toml Cargo.lock ./
# Dummy source files for workspace members.
# FIXME: Doesn't work if with members specifying a custom path to the entrypoint.
RUN find . -name Cargo.toml -exec sh -c \
    'dir=$(dirname "$1"); mkdir "$dir/src"; touch "$dir/src/lib.rs" "$dir/src/main.rs"' _ {} \; && \
    cargo chef prepare

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
LABEL org.opencontainers.image.source=https://github.com/arvid-persson1/m7011e-project
WORKDIR /app
COPY --from=builder --chmod=500 --chown=65532:65532 /user-service /app/user-service
EXPOSE 8000
ENV ROCKET_ADDRESS=0.0.0.0 \
    ROCKET_PORT=8000
ENTRYPOINT ["/app/user-service"]
