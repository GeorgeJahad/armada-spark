#!/bin/bash
set -e
source scripts/config.sh
source scripts/functions.sh

# generate armada docker image
#  run like so: scripts/createImage.sh /home/gbj/incoming/spark testing 2.13
SCALA_BIN_VERSION=`get_scala_bin_version $SPARK_HOME`
echo gbj $SCALA_BIN_VERSION
SPARK_VERSION=`get_spark_version $SPARK_HOME`
ARMADA_SPARK_HOME=`pwd`
BASE_CTX="$ARMADA_SPARK_HOME/target/tmp/docker/base"

cp versions/${SPARK_VERSION}/pom.xml pom.xml
cp versions/${SPARK_VERSION}/SparkSubmit.scala src/main/scala/org/apache/spark/deploy/ArmadaSparkSubmit.scala

# Get the dependencies to be copied into docker image
mvn --batch-mode clean package dependency:copy-dependencies
dependencies=(
    target/armada-cluster-manager_${SCALA_BIN_VERSION}-1.0.0-SNAPSHOT.jar
    target/dependency/lenses_${SCALA_BIN_VERSION}-0.11.13.jar
    target/dependency/scalapb-runtime_${SCALA_BIN_VERSION}-0.11.13.jar
    target/dependency/scalapb-runtime-grpc_${SCALA_BIN_VERSION}-0.11.13.jar
    target/dependency/armada-scala-client_${SCALA_BIN_VERSION}-0.1.0-SNAPSHOT.jar
)

spark_v3_dependencies=(
    target/dependency/grpc-api-1.47.1.jar
    target/dependency/grpc-core-1.47.1.jar
    target/dependency/grpc-netty-1.47.1.jar
    target/dependency/grpc-protobuf-1.47.1.jar
    target/dependency/grpc-context-1.47.1.jar
    target/dependency/grpc-stub-1.47.1.jar
    target/dependency/guava-31.0.1-android.jar
    target/dependency/failureaccess-1.0.1.jar
    target/dependency/perfmark-api-0.25.0.jar
)

spark_v334_dependencies=(
    target/dependency/netty-codec-http2-4.1.72.Final.jar
    target/dependency/netty-codec-http-4.1.72.Final.jar
    target/dependency/protobuf-java-3.19.6.jar
)

if [[ $SPARK_VERSION == 3* ]]; then
    dependencies+=("${spark_v3_dependencies[@]}")
fi

if [[ $SPARK_VERSION == "3.3.4" ]]; then
    dependencies+=("${spark_v334_dependencies[@]}")
fi

mkdir -p $BASE_CTX
cp -r $SPARK_HOME/assembly/target/scala-$SCALA_BIN_VERSION/jars $BASE_CTX/jars

if [ -e $BASE_CTX/jars/guava-14.0.1.jar ]; then
    rm  $BASE_CTX/jars/guava-14.0.1.jar
fi

if [ -e $BASE_CTX/jars/protobuf-java-2.5.0.jar ]; then
    rm  $BASE_CTX/jars/protobuf-java-2.5.0.jar
fi


# Copy dependencies to the docker image directory
cp "${dependencies[@]}" $BASE_CTX


# Make the image
cd $SPARK_HOME
ARMADA_SPARK_HOME=$ARMADA_SPARK_HOME SPARK_HOME=$SPARK_HOME $ARMADA_SPARK_HOME/scripts/docker-image-tool.sh -t $IMAGE_NAME build
