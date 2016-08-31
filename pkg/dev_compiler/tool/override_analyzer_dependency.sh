#!/bin/bash
set -e
cd $( dirname "${BASH_SOURCE[0]}" )/..

. ./tool/dependency_overrides.sh

checkout_dependency_override_from_github \
  analyzer dart-lang/sdk $1 /pkg/analyzer/
