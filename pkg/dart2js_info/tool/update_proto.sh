#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Expected exactly one argument which is the protoc_plugin version to use"
else
    echo "Using protoc_plugin version $1"
    dart pub global activate protoc_plugin "$1"
fi

protoc --proto_path="." --dart_out=lib/src/proto info.proto
dart format lib/src/proto
