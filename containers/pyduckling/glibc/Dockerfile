FROM quay.io/pypa/manylinux_2_28_x86_64
ARG MATURIN_VERSION
ARG PYTHON_VERSION

RUN ln -s /opt/python/cp${PYTHON_VERSION//.}-cp${PYTHON_VERSION//.}/bin/python /usr/bin/python \
    && ln -s /opt/python/cp${PYTHON_VERSION//.}-cp${PYTHON_VERSION//.}/bin/pip /usr/bin/pip
RUN yum install -y \
    tzdata \
    rust \
    cargo \
    pcre-devel \
    gmp-devel

RUN pipx install "maturin[patchelf]==${MATURIN_VERSION}"
