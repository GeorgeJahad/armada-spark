#!/bin/bash
set -euo pipefail

echo Submitting spark job to K8s.

# init environment variables
scripts="$(cd "$(dirname "$0")"; pwd)"
source "$scripts/init.sh"

JOBSET="${JOBSET:-k8s-spark}"

# Disable config maps until this is fixed: https://github.com/G-Research/spark/issues/109
DISABLE_CONFIG_MAP=true


SHORT_TEST="q41-v2.4"  #takes a few minutes
LONGER_TEST="q7-v2.4"  #takes half hour
MULTIPLE_TESTS="$SHORT_TEST,$LONGER_TEST,q9-v2.4" #takes a couple of hours
ALL_TESTS="" #currrently takes days


TESTS_TO_RUN="${TESTS_TO_RUN:-q14a-v2.4}"

# Run K8s Spark via docker image
docker run -e KUBECONFIG=/opt/spark/extraFiles/kubeconfig --rm --network host $IMAGE_NAME \
    /opt/spark/bin/spark-class org.apache.spark.deploy.SparkSubmit \
    --master $K8S_MASTER --deploy-mode cluster \
    --name k8s-spark-benchmark \
    --class com.amazonaws.eks.tpcds.BenchmarkSQL \
    --conf spark.kubernetes.executor.podTemplateFile=/opt/spark/conf/pod-template.yaml \
    --conf spark.kubernetes.driver.podTemplateFile=/opt/spark/conf/driver-pod-template.yaml \
    --conf spark.hadoop.fs.s3a.secret.key=$AWS_SECRET_ACCESS_KEY \
    --conf spark.hadoop.fs.s3a.access.key=$AWS_ACCESS_KEY_ID \
    --conf spark.kubernetes.container.image=$IMAGE_NAME \
    --conf spark.kubernetes.jobSetId=${JOBSET} \
    local:///opt/spark/jars/eks-spark-benchmark-assembly-1.0.jar \
    s3a://kafka-s3/data/benchmark/data/10t \
    s3a://kafka-s3/data/benchmark/results/k8s3 \
    /opt/tpcds-kit/tools \
    parquet \
    10000 \
    1 \
    false \
    $TESTS_TO_RUN \
    false