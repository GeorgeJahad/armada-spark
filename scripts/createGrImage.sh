#!/bin/bash
set -e

echo Building image

root="$(cd "$(dirname "$0")/.."; pwd)"
scripts="$(cd "$(dirname "$0")"; pwd)"
source "$scripts/init.sh"

mvn --batch-mode -DskipTests install

image_prefix1=image
image_tag1=image

IMAGE_NAME=image
docker build \
  --tag $IMAGE_NAME \
  --build-arg spark_base_image_prefix=$image_prefix1 \
  --build-arg spark_base_image_tag=$image_tag1 \
  --build-arg scala_binary_version=$SCALA_BIN_VERSION \
  --build-arg include_python=$INCLUDE_PYTHON \
  -f "$root/docker/Dockerfile" \
  "$root"


docker tag `docker image ls  $IMAGE_NAME --digests | tail -1 | awk '{print $3}'` $IMAGE_NAME
docker push $IMAGE_NAME

echo Successfully built and pushed Armada Spark image.
