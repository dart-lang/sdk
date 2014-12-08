#!/bin/bash
set -e

dart -c test/all_tests.dart

ls lib/*.dart bin/*.dart | dartanalyzer -b --fatal-warnings
