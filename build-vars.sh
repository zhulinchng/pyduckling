# common source for all build variables
export PYTHON3_VERSION_MIN=8
export PYTHON3_VERSION_MAX=12
export PYTHON3_VERSION_RANGE=$(seq "${PYTHON3_VERSION_MIN}" 1 "${PYTHON3_VERSION_MAX}")
export GHC_VERSION=8.8.4
export CABAL_VERSION=3.2.0.0
export ALPINE_VERSION_DUCKLING_FFI=3.12
export ALPINE_VERSION_PYDUCKLING=3.19
export MATURIN_VERSION=1.4.0
export IMAGE_PREFIX="ghcr.io/phihos/pyduckling"
export BUILD_IMAGE_DUCKLING_FFI=$IMAGE_PREFIX/duckling-ffi-build:alpine-${ALPINE_VERSION_DUCKLING_FFI}-ghc-${GHC_VERSION}-cabal-${CABAL_VERSION}
export BUILD_IMAGE_PYDUCKLING=$IMAGE_PREFIX/pyduckling-build:alpine-${ALPINE_VERSION_PYDUCKLING}-maturin-${MATURIN_VERSION}

function build_image_pyduckling_for_python3_version() {
  python3_version=$1
  libc_version=$2
  echo "$IMAGE_PREFIX/pyduckling-build:${libc_version}-python-3.${python3_version}-maturin-${MATURIN_VERSION}"
}
export -f build_image_pyduckling_for_python3_version
