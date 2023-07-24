FROM rust:1.70-bullseye as deps-builder

RUN cd /tmp && cargo new coelho
COPY Cargo.toml /tmp/coelho

WORKDIR /tmp/coelho
RUN cargo install cargo-build-deps
RUN cargo build-deps --release

##

FROM rust:bullseye
WORKDIR /coelho

COPY --from=deps-builder /tmp/coelho/target/ /coelho/target

COPY ./ /coelho
RUN cargo build --release
ENV FIREBASE_CRED firebase.json

CMD ["./target/release/coelho"]
