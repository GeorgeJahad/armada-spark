#!/bin/bash
cd ~/incoming/asp/
export k8s_url="https://192.168.146.121:6443"
KUBECONFIG=/home/gbj/incoming/t2 ./spark-3.5.5-bin-hadoop3/bin/spark-submit \
    --master k8s://$k8s_url \
    --deploy-mode cluster \
    --name spark-benchmark \
    --class com.amazonaws.eks.tpcds.BenchmarkSQL \
    --conf spark.default.parallelism=10 \
    --conf spark.sql.shuffle.partitions=10 \
    --conf spark.executor.instances=40 \
    --conf spark.kubernetes.container.image=gbj262/spark-benchmark:next4 \
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
    s3a://kafka-s3/data/benchmark/results/k8s2 \
    /opt/tpcds-kit/tools \
    parquet \
    10000 \
    1 \
    false \
    $TEST_NAME \
    true
