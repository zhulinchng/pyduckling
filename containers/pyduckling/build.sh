#!/usr/bin/env bash

set -eo pipefail

cd "${0%/*}" || exit # go to script dir

source ../../build-vars.sh

case "$LIBC_VERSION" in
  musl)
    cd musl
    ;;
  glibc)
    cd glibc
    ;;
  *)
    echo "Unsupported lib $2. Exiting..."
    exit 1
esac

docker buildx build \
  --build-arg="MATURIN_VERSION=${MATURIN_VERSION}" \
  --build-arg="PYTHON_VERSION=3.${PYTHON3_VERSION}" \
  -t "$(build_image_pyduckling_for_python3_version "$PYTHON3_VERSION" "$LIBC_VERSION")" .

if [[ "${PUSH_IMAGES}" ]]; then
  docker push "$(build_image_pyduckling_for_python3_version "$PYTHON3_VERSION" "$LIBC_VERSION")"
fi
