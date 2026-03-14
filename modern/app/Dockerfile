# ------------------------------------------------------------
# Stage 1 - Build
# ------------------------------------------------------------
FROM rust:1.92-bookworm AS builder

WORKDIR /app

COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN cargo build --release

# ------------------------------------------------------------
# Stage 2 - Runtime
# ------------------------------------------------------------
FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/target/release/app /usr/local/bin/mainframe-batch-modernizer

ENTRYPOINT ["/usr/local/bin/mainframe-batch-modernizer"]
CMD ["--input", "../../legacy/data/input_fixed.dat"]