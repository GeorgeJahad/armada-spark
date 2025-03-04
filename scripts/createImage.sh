
#!/bin/bash
set -e

# generate armada docker image
#  run like so: scripts/createImage.sh /home/gbj/incoming/spark testing 2.13
SPARK_ROOT=$1
IMAGE_NAME=$2
SCALA_BIN_VERSION=$3

# Get the dependencies to be copied into docker image
#mvn --batch-mode clean package dependency:copy-dependencies
dependencies=(
    target/armada-cluster-manager_${SCALA_BIN_VERSION}-1.0.0-SNAPSHOT.jar
    target/dependency/lenses_${SCALA_BIN_VERSION}-0.11.13.jar
    target/dependency/scalapb-runtime_${SCALA_BIN_VERSION}-0.11.13.jar
    target/dependency/scalapb-runtime-grpc_${SCALA_BIN_VERSION}-0.11.13.jar
    target/dependency/scala-armada-client_${SCALA_BIN_VERSION}-0.1.0-SNAPSHOT.jar

    target/dependency/grpc-api-1.47.1.jar
    target/dependency/grpc-context-1.47.1.jar
    target/dependency/grpc-core-1.47.1.jar
    target/dependency/grpc-netty-1.47.1.jar
    target/dependency/grpc-protobuf-1.47.1.jar
    target/dependency/grpc-protobuf-lite-1.47.1.jar
    target/dependency/grpc-stub-1.47.1.jar
    target/dependency/netty-codec-http2-4.1.72.Final.jar
    target/dependency/guava-31.0.1-android.jar
    target/dependency/protobuf-java-3.19.6.jar
    target/dependency/failureaccess-1.0.1.jar
    target/dependency/perfmark-api-0.25.0.jar
    target/dependency/netty-codec-http-4.1.72.Final.jar
)

# Copy dependencies to the docker image directory
cp "${dependencies[@]}" $SPARK_ROOT/assembly/target/scala-${SCALA_BIN_VERSION}/jars/

# Make the image
cd $SPARK_ROOT
./bin/docker-image-tool.sh -t $IMAGE_NAME build
