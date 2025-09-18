#!/usr/bin/env bash

set -euo pipefail

cd "${0%/*}" || exit # go to script dir

source ../../build-vars.sh

docker buildx build \
  --build-arg="GHC_VERSION=${GHC_VERSION}" \
  --build-arg="CABAL_VERSION=${CABAL_VERSION}" \
  --build-arg="ALPINE_VERSION=${ALPINE_VERSION_DUCKLING_FFI}" \
  -t "${BUILD_IMAGE_DUCKLING_FFI}" .

if [[ -n "${PUSH_IMAGES:-}" ]]; then
  docker push "${BUILD_IMAGE_DUCKLING_FFI}"
fi
