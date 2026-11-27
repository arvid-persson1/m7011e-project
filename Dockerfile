FROM lukemathwalker/cargo-chef:0.1.78-rust-1.100-slim-bookworm AS base
WORKDIR /app

FROM base AS planner
COPY . .
RUN cargo chef prepare

FROM base AS builder
COPY --from=planner /app/recipe.json recipe.json
ARG SERVICE
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    cargo chef cook --release --bin ${SERVICE}
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    cargo build --locked --release --bin ${SERVICE} && \
    cp target/release/${SERVICE} /service

FROM gcr.io/distroless/cc-debian12:nonroot AS runtime
LABEL org.opencontainers.image.source=https://github.com/arvid-persson1/m7011e-project
EXPOSE 8000
ENV ROCKET_ADDRESS=0.0.0.0 \
    ROCKET_PORT=8000
WORKDIR /app
COPY --from=builder --chmod=500 --chown=65532:65532 /service /app/service
ENTRYPOINT ["/app/service"]
