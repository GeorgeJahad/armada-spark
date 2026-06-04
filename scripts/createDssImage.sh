#!/bin/bash
set -e

# Builds the distributed shuffle storage spark image;
# Also includes the benchmarking tools
# NOTE this script only needs to be run when the distributed shuffle storage spark branch is modified.
# Normally you won't need to use this script as the image will be pulled from docker.


scripts="$(cd "$(dirname "$0")"; pwd)"
source "$scripts/init.sh"

# these utilities are needed to build benchmarking tools
# sudo apt-get install gcc make flex bison byacc git

# Check if the 'lex' command exists
if ! command -v lex &> /dev/null; then
    echo "Error: 'lex' command not found."
    echo 'you need to run "apt-get install gcc make flex bison byacc git"'
    exit 1
fi

tmp_dir=$(mktemp -d)
echo Creating temp dir: $tmp_dir
cd $tmp_dir

repo=${ARMADA_DSS_REPO:-https://github.com/G-Research/spark}
repo_dir=`basename $repo`
branch=${ARMADA_DSS_BRANCH:-armada/push-task-result-to-driver-bm-v3.5.3}

# create the spark image with distributed shuffle storage support
git clone $repo
cd $repo_dir
git checkout $branch

export SPARK_HOME=`pwd`
DSS_IMAGE_TAG="spark.dss${SPARK_VERSION}.img"
./build/mvn clean install --batch-mode -Dscalastyle.skip=true -DskipTests  -Pkubernetes -Phadoop-cloud -Pscala-$SCALA_BIN_VERSION
./bin/docker-image-tool.sh -u 185 -t "$DSS_IMAGE_TAG"  -p ./resource-managers/kubernetes/docker/src/main/dockerfiles/spark/bindings/python/Dockerfile build
cd ..

# build the benchmarking tools
mkdir docker
cd docker
databricks_repo=${DATABRICKS_REPO:-https://github.com/databricks/tpcds-kit}
git clone $databricks_repo tpcds-kit
pushd tpcds-kit/tools
make
popd


# get the benchmark jar files
mkdir jars
benchmark_jar_basename=$(basename "$ARMADA_BENCHMARK_JAR")
if [[ "$SPARK_VERSION" != "4."* ]]; then
    # this was built from https://github.com/GeorgeJahad/eks-spark-benchmark/tree/hashOutput
    wget --no-check-certificate "https://drive.google.com/uc?export=download&id=1fjGRrLmbLygqdP-ugoTHLUbNMkTTxvcO" \
         -O  "jars/$benchmark_jar_basename"
else
    cp "/tmp/$benchmark_jar_basename" jars/
fi

# Copy the cert file into the docker dir and add docker commands to import it
# The cert file is need for clusters using TLS with self signed certs
# e.g. To use our tig cluster, retrieve the cert from the jumpbox here:
#  /usr/local/share/ca-certificates/testkube-ca.crt
ARMADA_SKIP_CERT=${ARMADA_SKIP_CERT:-""}
if [[ $ARMADA_SKIP_CERT != "true" ]]; then
    if [[ $1 == "" ]]; then
        echo "need to pass the cert arg, (unless ARMADA_SKIP_CERT is set)."
    fi
    echo copying $1
    cp $1 ca.crt
    IMPORT_CERT_COMMANDS="COPY ca.crt /tmp/ca.crt
RUN keytool -importcert -file /tmp/ca.crt -keystore \$(find / -name cacerts -type f 2>/dev/null | head -1) -alias mycert -storepass changeit -noprompt"
else
    IMPORT_CERT_COMMANDS=""
fi

git -C ../$repo_dir rev-parse HEAD > BUILD-COMMIT
cat <<EOF > Dockerfile
FROM spark-py:$DSS_IMAGE_TAG

# Reset to root to run installation tasks
USER 0

RUN mkdir /opt/tools
COPY tpcds-kit /opt/tools/tpcds-kit
COPY jars/* /opt/spark/jars
COPY BUILD-COMMIT /opt/spark/BUILD-COMMIT
$IMPORT_CERT_COMMANDS
EOF

docker build --tag spark-py:${DSS_IMAGE_TAG}2 .

echo ""
echo "DSS image built: spark-py:${DSS_IMAGE_TAG}2"
echo "To use this image, set in scripts/config.sh:"
echo "  DSS_PREFIX=spark-py"
echo "  DSS_TAG=${DSS_IMAGE_TAG}2"

