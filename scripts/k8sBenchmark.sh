#!/bin/bash
set -euo pipefail

echo Submitting spark job to k8s


JOBSET="${JOBSET:-k8s-spark}"

#export SPARK_CONF_DIR=/opt/spark3/conf


spark-submit --name $JOBSET --deploy-mode cluster \
--conf spark.kubernetes.container.image=image
--conf spark.driver.memory=2048m \
--conf spark.executor.instances=10 \
--conf spark.executor.cores=1 \
--conf spark.executor.memory=4096m \
--conf spark.shuffle.service.enabled=false \
--conf spark.dynamicAllocation.enabled=false \
--conf spark.kubernetes.executor.deleteOnTermination=true \
--conf spark.hadoop.fs.s3a.access.key=${AWS_ACCESS_KEY} \
--conf spark.hadoop.fs.s3a.secret.key=${AWS_SECRET_KEY} \
--class uk.co.gresearch.bigdata.tpcds.BenchmarkSQL \
https://benchmark.jar
s3a://10t
/tmp \
/tmp/databricks--tpcds-kit/tools \
parquet \
10000 \
1 \
false \
\"\" \
false
