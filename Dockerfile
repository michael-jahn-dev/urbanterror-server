# Urban Terror 4.3 dedicated server
# Official FrozenSand ioq3 engine, built from source (amd64 + arm64)
# Game data is NOT included and must be mounted to /urt

FROM debian:bookworm-slim AS build
ARG ENGINE_REF=master
RUN apt-get update \
  && apt-get install -y --no-install-recommends git build-essential ca-certificates \
  && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch "${ENGINE_REF}" \
  https://github.com/FrozenSand/ioq3-for-UrbanTerror-4.git /src
WORKDIR /src
# Add aarch64 to the list of known Linux architectures (no-op on x86_64)
RUN sed -i 's/#elif defined __arm__/#elif defined __aarch64__\n#define ARCH_STRING "aarch64"\n#elif defined __arm__/' \
  code/qcommon/q_platform.h
RUN make BUILD_SERVER=1 BUILD_CLIENT=0 BUILD_CLIENT_SMP=0 USE_CURL=0 \
  OPTIMIZE="-O2 -fcommon" \
  && cp build/release-linux-*/Quake3-UrT-Ded.* /urt-ded

FROM debian:bookworm-slim
LABEL org.opencontainers.image.title="urbanterror-server" \
  org.opencontainers.image.description="Urban Terror 4.3 dedicated server with the official FrozenSand engine (amd64/arm64)" \
  org.opencontainers.image.licenses="GPL-2.0"
COPY --from=build /urt-ded /usr/local/bin/urt-ded
ENV HOME=/urt
USER 1000:1000
WORKDIR /urt
EXPOSE 27960/udp
ENTRYPOINT ["urt-ded", "+set", "fs_game", "q3ut4", "+set", "fs_basepath", "/urt", "+set", "fs_homepath", "/urt"]
CMD ["+set", "dedicated", "2", "+set", "net_port", "27960", "+exec", "server.cfg"]
