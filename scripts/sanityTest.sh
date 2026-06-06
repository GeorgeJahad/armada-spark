#!/bin/bash
set -euo pipefail

scripts="$(cd "$(dirname "$0")"; pwd)"
root="$(cd "$scripts/.."; pwd)"
cd "$root"

# Prefix non-empty echoes with "SanityTest: " so this script's output is
# easy to distinguish from output produced by the spark-submit/benchmark
# subprocesses it invokes.
echo() {
    if [ "$#" -eq 0 ] || [ -z "$*" ]; then
        builtin echo
    else
        builtin echo "SanityTest: $*"
    fi
}

VERSIONS=(
    "3.3.4 2.12.18"
    "3.5.3 2.12.18"
    "4.1.1 2.13.14"
)

for entry in "${VERSIONS[@]}"; do
    read -r spark_ver scala_ver <<< "$entry"
    echo ""
    echo "=============================================="
    echo "  Building Spark $spark_ver / Scala $scala_ver"
    echo "=============================================="
    echo ""

    export IMAGE_NAME=gbj262/${spark_ver}-$(uuidgen)
    echo image is $IMAGE_NAME
    scripts/set-version.sh "$spark_ver" "$scala_ver"
    mvn --batch-mode -DskipTests clean install >& /tmp/m1; tail /tmp/m1
    scripts/createImage.sh -p

    echo ""
    echo "----------------------------------------------"
    echo "  Testing Spark $spark_ver: cluster/dynamic"
    echo "----------------------------------------------"
    echo ""
    scripts/submitArmadaSpark.sh -M cluster -A dynamic 1000

    echo ""
    echo "----------------------------------------------"
    echo "  Testing Spark $spark_ver: cluster/static"
    echo "----------------------------------------------"
    echo ""
    scripts/submitArmadaSpark.sh -M cluster -A static 1000

    echo ""
    echo "----------------------------------------------"
    echo "  Testing Spark $spark_ver: client/static"
    echo "----------------------------------------------"
    echo ""
    scripts/submitArmadaSpark.sh -M client -A static 1000

    echo ""
    echo "----------------------------------------------"
    echo "  Testing Spark $spark_ver: client/dynamic"
    echo "----------------------------------------------"
    echo ""
    scripts/submitArmadaSpark.sh -M client -A dynamic 1000

    echo ""
    echo "----------------------------------------------"
    echo "  Testing Spark $spark_ver: benchmark"
    echo "----------------------------------------------"
    echo ""
    scripts/benchmark.sh -M cluster

    echo ""
    echo "=== Spark $spark_ver PASSED ==="
    echo ""
done

echo ""
echo "=============================================="
echo "  ALL VERSIONS BUILT AND TESTED SUCCESSFULLY"
echo "=============================================="