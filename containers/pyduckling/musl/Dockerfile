ARG PYTHON_VERSION
FROM python:${PYTHON_VERSION}-alpine
ARG MATURIN_VERSION

RUN apk add --no-cache \
    bash \
    tzdata \
    rust \
    cargo \
    cmake \
    automake \
    autoconf \
    patchelf \
    build-base \
    pcre-dev gmp-dev \
    tar
RUN pip install --break-system-packages "maturin[patchelf]==${MATURIN_VERSION}"
