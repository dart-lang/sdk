#!/bin/bash
set -e

dart -c test/all_tests.dart

ls bin/*.dart lib/*.dart | dartanalyzer -b --fatal-warnings
