#!/bin/bash
set -e
DIR=$(dirname "${BASH_SOURCE[0]}")
$DIR/build_sdk.sh
$DIR/test.sh
