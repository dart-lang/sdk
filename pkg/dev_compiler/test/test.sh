#!/bin/bash
set -e
echo warning: this script has been renamed to ./tool/presubmit.sh
$(dirname "${BASH_SOURCE[0]}")/../tool/presubmit.sh
