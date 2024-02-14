#!/usr/bin/env bash

set -eo pipefail

cd "${0%/*}" || exit # go to script dir

# load common vars
source build-vars.sh

export USER_HOME_CACHE_PATH="$(pwd)"/.cache/userhome
export STATIC_LIB_CONTAINER_NAME="pyduckling-build-static-lib"
export PYDUCKLING_CONTAINER_NAME="pyduckling-build-wheel"

if ! command -v docker &> /dev/null
then
    echo "docker could not be found"
    exit 1
fi

function cleanup {
  echo "Cleaning up..."
  docker rm -f "${STATIC_LIB_CONTAINER_NAME}" > /dev/null 2>&1 || true
  for python3_version in $PYTHON3_VERSION_RANGE; do
    CONTAINER_NAME="${PYDUCKLING_CONTAINER_NAME}-${python3_version}-glibc"
    docker rm -f "${CONTAINER_NAME}" > /dev/null 2>&1 || true
  done
  for python3_version in $PYTHON3_VERSION_RANGE; do
    CONTAINER_NAME="${PYDUCKLING_CONTAINER_NAME}-${python3_version}-musl"
    docker rm -f "${CONTAINER_NAME}" > /dev/null 2>&1 || true
  done
}
trap cleanup EXIT

function build_pyduckling_build_image {
  python3_version=$1
  libc_version=$2
  BUILD_IMAGE=$(build_image_pyduckling_for_python3_version "$python3_version" "$libc_version")
  if docker manifest inspect "${BUILD_IMAGE}" > /dev/null 2>&1; then
    echo "Image \"${BUILD_IMAGE}\" already available. Skipping build..."
  else
    echo "Building \"${BUILD_IMAGE}\"..."
    export PYTHON3_VERSION=$python3_version
    export LIBC_VERSION=$libc_version
    containers/pyduckling/build.sh
  fi
}
export -f build_pyduckling_build_image

function build_python_package() {
  python3_version=$1
  libc_version=$2
  BUILD_IMAGE=$(build_image_pyduckling_for_python3_version "$python3_version" "$libc_version")
  CONTAINER_NAME="${PYDUCKLING_CONTAINER_NAME}-${python3_version}-${libc_version}"
  VENV_NAME="venv-3.${python3_version}-${libc_version}"
  echo "Building wheel for Python 3.${python3_version} in ${BUILD_IMAGE}..."
  docker run \
    --mount type=bind,source="$(pwd)",target=/repo \
    --mount type=bind,source="${USER_HOME_CACHE_PATH}",target=/userhome \
    --user "$(id -u):$(id -g)" \
    --name "${CONTAINER_NAME}" \
    -e HOME=/userhome \
    -e VENV="/userhome/${VENV_NAME}" \
    --detach \
    "${BUILD_IMAGE}" \
    sleep infinity
  docker exec "${CONTAINER_NAME}" bash -c 'if [[ ! -d "$VENV" ]]; then python -m venv "$VENV"; fi'
  docker exec "${CONTAINER_NAME}" bash -c 'source "$VENV/bin/activate" && pip install pytest pytest-cov coverage pendulum'
  docker exec "${CONTAINER_NAME}" bash -c 'source "$VENV/bin/activate" && cd /repo && maturin develop'
  docker exec "${CONTAINER_NAME}" bash -c 'source "$VENV/bin/activate" && cd /repo && pytest -x -v --cov=duckling duckling/tests'
  docker exec "${CONTAINER_NAME}" bash -c 'source "$VENV/bin/activate" && cd /repo && maturin build -r'
  if [[ "$PUBLISH" == "1" ]]; then
    docker exec -e MATURIN_USERNAME -e MATURIN_PASSWORD "${CONTAINER_NAME}" bash -c 'source "$VENV/bin/activate" && cd /repo && maturin publish --skip-existing --no-sdist'
  fi
}
export -f build_python_package

# --- build necessary container images
if docker manifest inspect "${BUILD_IMAGE_DUCKLING_FFI}" > /dev/null 2>&1; then
  echo "Image \"${BUILD_IMAGE_DUCKLING_FFI}\" already available. Skipping build..."
else
  echo "Building \"${BUILD_IMAGE_DUCKLING_FFI}\"..."
  containers/duckling-ffi/build.sh
fi
echo -n $PYTHON3_VERSION_RANGE | parallel -j0 --halt now,fail=1  -d ' ' 'build_pyduckling_build_image {} glibc'
echo -n $PYTHON3_VERSION_RANGE | parallel -j0 --halt now,fail=1  -d ' ' 'build_pyduckling_build_image {} musl'

# --- create cache directory for faster repeated execution
mkdir -p "${USER_HOME_CACHE_PATH}"

# --- build the statically linked library file
echo "---"
echo "Building statically linked \"libducklingffi.a\"..."
docker run \
  --mount type=bind,source="$(pwd)"/duckling-ffi,target=/duckling-ffi \
  --mount type=bind,source="${USER_HOME_CACHE_PATH}",target=/userhome \
  --user "$(id -u):$(id -g)" \
  --name "${STATIC_LIB_CONTAINER_NAME}" \
  -e HOME=/userhome \
  --detach \
  "${BUILD_IMAGE_DUCKLING_FFI}" \
  sleep infinity
docker exec "${STATIC_LIB_CONTAINER_NAME}" bash -c 'cd /duckling-ffi && stack build --no-install-ghc --system-ghc --allow-different-user --force-dirty'
docker cp "${STATIC_LIB_CONTAINER_NAME}:/duckling-ffi/libducklingffi.a" ext_lib/libducklingffi.a

# --- build binary distributions
echo "---"
echo "Building GLIBC wheels for all python versions..."
echo -n $PYTHON3_VERSION_RANGE | parallel -j0 --halt now,fail=1  -d ' ' 'build_python_package {} glibc'
echo "---"
echo "Building MUSL wheels for all python versions..."
echo -n $PYTHON3_VERSION_RANGE | parallel -j0 --halt now,fail=1  -d ' ' 'build_python_package {} musl'
