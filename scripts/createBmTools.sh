#!/bin/bash
set -e

# Check if the 'lex' command exists
if ! command -v lex &> /dev/null; then
    echo "Error: 'lex' command not found."
    echo 'you need to run "apt-get install flex"'
    exit 1
fi

root="$(cd "$(dirname "$0")/.."; pwd)"
cd extraFiles
git clone https://github/databricks--tpcds-kit
cd databricks--tpcds-kit/tools
make


