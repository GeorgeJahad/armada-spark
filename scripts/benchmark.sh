#!/bin/bash
set -euo pipefail

echo Submitting spark job to Armada.

# init environment variables
scripts="$(cd "$(dirname "$0")"; pwd)"
source "$scripts/init.sh"

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


TESTS_TO_RUN="${TESTS_TO_RUN:-q41-v2.4}"
IMAGE_NAME=image

# Run Armada Spark via docker image
docker run -v $scripts/../conf:/opt/spark/conf --rm --network host $IMAGE_NAME \
    /opt/spark/bin/spark-class org.apache.spark.deploy.ArmadaSparkSubmit \
    --master $ARMADA_MASTER --deploy-mode cluster \
    --name spark-benchmark \
    --class BenchmarkSQL \
    $AUTH_ARG \
    --conf spark.home=/opt/spark \
    --conf spark.armada.container.image=$IMAGE_NAME \
    --conf spark.armada.jobSetId=${JOBSET} \
    --conf spark.armada.runAsUser=1000 \
    --conf spark.kubernetes.file.upload.path=/tmp \
    --conf spark.kubernetes.executor.disableConfigMap=$DISABLE_CONFIG_MAP \
    --conf spark.local.dir=/tmp \
    --conf spark.executor.instances=100 \
    --conf spark.shuffle.service.enabled=false \
    --conf spark.hadoop.fs.s3a.bucket.$SPARK_PLAYPEN.endpoint=$SPARK_PLAYPEN_ENDPOINT \
    --conf spark.kubernetes.driver.secretKeyRef.AWS_SECRET_ACCESS_KEY=$SPARK_SECRET_KEY:secret_key \
    --conf spark.kubernetes.executor.secretKeyRef.AWS_SECRET_ACCESS_KEY=$SPARK_SECRET_KEY:secret_key \
    --conf spark.kubernetes.driver.secretKeyRef.AWS_ACCESS_KEY_ID=$SPARK_SECRET_KEY:access_key \
    --conf spark.kubernetes.executor.secretKeyRef.AWS_ACCESS_KEY_ID=$SPARK_SECRET_KEY:access_key \
    local:///opt/spark/jars/gr-spark-benchmark_2.12-3.3.1-1.0-SNAPSHOT-assembly.jar \
    s3a://squirrel-vast/spark-on-k8s/benchmarks/data/10tb \
    s3a://$SPARK_PLAYPEN/benchmark/armada27 \
    /opt/spark/extraFiles/databricks--tpcds-kit/tools \
    parquet \
    10000 \
    1 \
    false \
    $TESTS_TO_RUN \
    false