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


TESTS_TO_RUN="${TESTS_TO_RUN:-q14a-v2.4}"

# Run Armada Spark via docker image
docker run -v $scripts/../conf:/opt/spark/conf --rm --network host $IMAGE_NAME \
    /opt/spark/bin/spark-class org.apache.spark.deploy.ArmadaSparkSubmit \
    --master $ARMADA_MASTER --deploy-mode cluster \
    --name spark-benchmark \
    --class com.amazonaws.eks.tpcds.BenchmarkSQL \
    $AUTH_ARG \
    --conf spark.hadoop.fs.s3a.secret.key=$AWS_SECRET_ACCESS_KEY \
    --conf spark.hadoop.fs.s3a.access.key=$AWS_ACCESS_KEY_ID \
    --conf spark.default.parallelism=10 \
    --conf spark.sql.shuffle.partitions=10 \
    --conf spark.executor.instances=40 \
    --conf spark.home=/opt/spark \
    --conf spark.armada.container.image=$IMAGE_NAME \
    --conf spark.armada.jobSetId=${JOBSET} \
    --conf spark.kubernetes.file.upload.path=/tmp \
    --conf spark.kubernetes.executor.disableConfigMap=$DISABLE_CONFIG_MAP \
    --conf spark.local.dir=/tmp \
    --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark-sa \
    --conf spark.hadoop.fs.s3a.endpoint=http://192.168.59.6 \
    --conf spark.driver.memory=5g --conf spark.executor.memory=46g \
    --conf spark.hadoop.fs.s3a.committer.name=file \
    --conf spark.hadoop.fs.s3a.connection.maximum=10000 \
    --conf spark.hadoop.fs.s3a.fast.upload=true \
    --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
    --conf spark.hadoop.fs.s3a.multipart.size=32M \
    --conf spark.hadoop.fs.s3a.multipart.threshold=320M \
    --conf spark.hadoop.fs.s3a.path.style.access=true \
    --conf spark.hadoop.fs.s3a.threads.max=5000 \
    --conf mapreduce.outputcommitter.factory.scheme.s3a=org.apache.hadoop.fs.s3a.commit.S3ACommitterFactory \
    local:///opt/spark/examples/jars/eks-spark-benchmark-assembly-1.0.jar \
    s3a://kafka-s3/data/benchmark/data/10t \
    s3a://kafka-s3/data/benchmark/results/armada1 \
    /opt/tpcds-kit/tools \
    parquet \
    10000 \
    1 \
    false \
    $TESTS_TO_RUN \
    false