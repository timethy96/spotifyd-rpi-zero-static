# ── Base setup ────────────────────────────────────────────────────────────────
FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Install build tools and utils
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    git \
    wget \
    xz-utils \
    bzip2 \
    nasm \
    pkg-config \
    ca-certificates \
    perl \
    libtext-template-perl \
    file \
    && rm -rf /var/lib/apt/lists/*

# ── Install Zig ──────────────────────────────────────────────────────────────
# We use Zig 0.13.0 (stable) as our C/C++ cross-compiler and linker.
RUN cd /tmp && \
    wget https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz && \
    tar -xf zig-linux-x86_64-0.13.0.tar.xz && \
    mv zig-linux-x86_64-0.13.0 /usr/local/zig && \
    ln -s /usr/local/zig/zig /usr/local/bin/zig && \
    rm zig-linux-x86_64-0.13.0.tar.xz

# Create wrapper scripts for the cross-compiler toolchain
RUN echo '#!/bin/bash' > /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo 'new_args=()' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo 'skip_next=0' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo 'for arg in "$@"; do' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo '  if [ "$skip_next" -eq 1 ]; then skip_next=0; continue; fi' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo '  if [[ "$arg" == "-mcpu"* ]]; then continue; fi' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo '  if [[ "$arg" == "-mcpu" ]]; then skip_next=1; continue; fi' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo '  if [[ "$arg" == "-march"* ]]; then continue; fi' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo '  if [[ "$arg" == "-march" ]]; then skip_next=1; continue; fi' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo '  if [[ "$arg" == "-mfpu"* ]]; then continue; fi' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo '  if [[ "$arg" == "-mfloat-abi"* ]]; then continue; fi' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo '  if [[ "$arg" == "-marm" ]]; then continue; fi' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo '  if [[ "$arg" == "-mthumb" ]]; then continue; fi' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo '  if [[ "$arg" == "-target" ]]; then skip_next=1; continue; fi' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo '  if [[ "$arg" == "--target="* ]]; then continue; fi' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo '  new_args+=("$arg")' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo 'done' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    echo 'exec zig cc -target arm-linux-musleabihf -mcpu=arm1176jzf_s -mfloat-abi=hard -mfpu=vfp "${new_args[@]}"' >> /usr/local/bin/arm-linux-musleabihf-gcc && \
    chmod +x /usr/local/bin/arm-linux-musleabihf-gcc

RUN echo '#!/bin/bash' > /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo 'new_args=()' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo 'skip_next=0' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo 'for arg in "$@"; do' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo '  if [ "$skip_next" -eq 1 ]; then skip_next=0; continue; fi' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo '  if [[ "$arg" == "-mcpu"* ]]; then continue; fi' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo '  if [[ "$arg" == "-mcpu" ]]; then skip_next=1; continue; fi' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo '  if [[ "$arg" == "-march"* ]]; then continue; fi' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo '  if [[ "$arg" == "-march" ]]; then skip_next=1; continue; fi' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo '  if [[ "$arg" == "-mfpu"* ]]; then continue; fi' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo '  if [[ "$arg" == "-mfloat-abi"* ]]; then continue; fi' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo '  if [[ "$arg" == "-marm" ]]; then continue; fi' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo '  if [[ "$arg" == "-mthumb" ]]; then continue; fi' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo '  if [[ "$arg" == "-target" ]]; then skip_next=1; continue; fi' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo '  if [[ "$arg" == "--target="* ]]; then continue; fi' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo '  new_args+=("$arg")' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo 'done' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    echo 'exec zig c++ -target arm-linux-musleabihf -mcpu=arm1176jzf_s -mfloat-abi=hard -mfpu=vfp "${new_args[@]}"' >> /usr/local/bin/arm-linux-musleabihf-g++ && \
    chmod +x /usr/local/bin/arm-linux-musleabihf-g++

RUN echo '#!/bin/bash' > /usr/local/bin/arm-linux-musleabihf-ar && \
    echo 'exec zig ar "$@"' >> /usr/local/bin/arm-linux-musleabihf-ar && \
    chmod +x /usr/local/bin/arm-linux-musleabihf-ar

RUN echo '#!/bin/bash' > /usr/local/bin/arm-linux-musleabihf-ranlib && \
    echo 'exec zig ranlib "$@"' >> /usr/local/bin/arm-linux-musleabihf-ranlib && \
    chmod +x /usr/local/bin/arm-linux-musleabihf-ranlib

# ── Build ALSA-lib (Static) ─────────────────────────────────────────────────
WORKDIR /tmp

# 1. Download & Extract - ALSA-lib 1.2.9 (stable, widely compatible)
RUN curl -fLO https://www.alsa-project.org/files/pub/lib/alsa-lib-1.2.9.tar.bz2 && \
    tar -xf alsa-lib-1.2.9.tar.bz2

# Compiler Check to debug
RUN echo 'int main(){return 0;}' > test.c && \
    arm-linux-musleabihf-gcc test.c -o test && \
    rm test test.c

# 2. Configure
RUN cd alsa-lib-1.2.9 && \
    ./configure \
    --host=arm-linux-musleabihf \
    --prefix=/build/sysroot/usr \
    --disable-shared \
    --enable-static \
    --disable-python \
    --disable-topology \
    --with-configdir=/usr/share/alsa \
    CC="arm-linux-musleabihf-gcc" \
    AR="arm-linux-musleabihf-ar" \
    RANLIB="arm-linux-musleabihf-ranlib" > /dev/null

# 3. Build & Install
RUN cd alsa-lib-1.2.9 && \
    make -j$(nproc) > /dev/null && \
    make install > /dev/null

# ── Build OpenSSL (Static) ───────────────────────────────────────────────────
WORKDIR /tmp

# 1. Download & Extract - OpenSSL 1.1.1w (LTS, compatible with Zig musl cross-compile)
RUN curl -fLO https://www.openssl.org/source/openssl-1.1.1w.tar.gz && \
    tar -xf openssl-1.1.1w.tar.gz

# 2. Configure
RUN cd openssl-1.1.1w && \
    ./Configure linux-generic32 \
    --prefix=/build/sysroot/usr \
    --openssldir=/build/sysroot/usr/ssl \
    no-shared \
    no-tests \
    CC="arm-linux-musleabihf-gcc" \
    AR="arm-linux-musleabihf-ar" \
    RANLIB="arm-linux-musleabihf-ranlib" > /dev/null

# 3. Build & Install
RUN cd openssl-1.1.1w && \
    make -j$(nproc) > /dev/null && \
    make install_sw > /dev/null

# ── Rust Toolchain ───────────────────────────────────────────────────────────
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup target add arm-unknown-linux-musleabihf

# ── Build Env ────────────────────────────────────────────────────────────────
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV PKG_CONFIG_ALL_STATIC=1
ENV PKG_CONFIG_PATH=/build/sysroot/usr/lib/pkgconfig

# Point to manually built OpenSSL (spotifyd uses openssl directly)
ENV OPENSSL_DIR=/build/sysroot/usr
ENV OPENSSL_STATIC=1

# Force cc-rs to use our wrapper
ENV CC_arm_unknown_linux_musleabihf=arm-linux-musleabihf-gcc
ENV CXX_arm_unknown_linux_musleabihf=arm-linux-musleabihf-g++
ENV AR_arm_unknown_linux_musleabihf=arm-linux-musleabihf-ar

# Prevent Rust from linking its bundled Musl startup files (conflict with Zig)
ENV RUSTFLAGS="-C link-self-contained=no"

# ── Build Spotifyd ───────────────────────────────────────────────────────────
WORKDIR /build/spotifyd
COPY . .
RUN rm -rf target

# Switch to bash for pipefail
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN pkg-config --list-all
RUN pkg-config --modversion alsa

# We use the generic Cargo build now.
RUN cargo build \
    --release \
    --target=arm-unknown-linux-musleabihf \
    --no-default-features \
    --features alsa_backend \
    --config "target.arm-unknown-linux-musleabihf.linker='arm-linux-musleabihf-gcc'" -v > build.log 2>&1 || (cat build.log && exit 1)

RUN cat build.log

# ── Export ───────────────────────────────────────────────────────────────────
FROM scratch AS export
COPY --from=0 /build/spotifyd/target/arm-unknown-linux-musleabihf/release/spotifyd .

