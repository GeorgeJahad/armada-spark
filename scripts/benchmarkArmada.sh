#!/bin/bash
set -euo pipefail

echo Submitting spark job to Armada.
echo gbj1

# init environment variables
scripts="$(cd "$(dirname "$0")"; pwd)"
source "$scripts/init.sh"

echo gbj2
JOBSET="${JOBSET:-armada-spark}"


if [ "$ARMADA_AUTH_TOKEN" != "" ]; then
    AUTH_ARG=" --conf spark.armada.auth.token=$ARMADA_AUTH_TOKEN"
else
    AUTH_ARG=""
fi

# Disable config maps until this is fixed: https://github.com/G-Research/spark/issues/109
DISABLE_CONFIG_MAP=true


SHORT_TEST="q41-v2.4"  #takes a few minutes
LONGER_TEST="q7-v2.4"  #takes half hour
MULTIPLE_TESTS="$SHORT_TEST,$LONGER_TEST,q9-v2.4" #takes a couple of hours
ALL_TESTS="" #currrently takes days


TESTS_TO_RUN="${TESTS_TO_RUN:-q14a-v2.4}"

echo gbj3
# Run Armada Spark via docker image
docker run --rm --network host $IMAGE_NAME \
    /opt/spark/bin/spark-class org.apache.spark.deploy.ArmadaSparkSubmit \
    --master $ARMADA_MASTER --deploy-mode cluster \
    --name spark-benchmark \
    --class com.amazonaws.eks.tpcds.BenchmarkSQL \
    $AUTH_ARG \
    --conf spark.hadoop.fs.s3a.secret.key=$AWS_SECRET_ACCESS_KEY \
    --conf spark.hadoop.fs.s3a.access.key=$AWS_ACCESS_KEY_ID \
    --conf spark.armada.container.image=$IMAGE_NAME \
    --conf spark.armada.jobSetId=${JOBSET} \
    --conf spark.kubernetes.file.upload.path=/tmp \
    local:///opt/spark/jars/eks-spark-benchmark-assembly-1.0.jar \
    s3a://kafka-s3/data/benchmark/data/10t \
    s3a://kafka-s3/data/benchmark/results/armada2 \
    /opt/tpcds-kit/tools \
    parquet \
    10000 \
    1 \
    false \
    $TESTS_TO_RUN \
    false