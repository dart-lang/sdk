#! /bin/bash

# This script expects the following arguments
# $1: Path to dart executable
# $2: Path to dart echoing script
# $3: Argument to dart echoing script (0, 1 or 2)
# $4: File for output from piping stdout and stderr
# $5: File prefix for output from redirecting stdout and stderr to a file.

# Test piping and stdio file redirection.
echo "Hello" | $1 $2 $3 2>&1 | cat - > $4
$1 $2 $3 < $4 > $5.stdout 2> $5.stderr
$1 $2 $3 < $4 >> $5.stdout 2>> $5.stderr
