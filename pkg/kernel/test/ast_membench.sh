#!/bin/sh
testdir=$(dirname $0)
first_input=10
first_output=$(mktemp)
dart --print-metrics $testdir/ast_membench.dart $1 $first_input >/dev/null 2>$first_output
second_input=20
second_output=$(mktemp)
dart --print-metrics $testdir/ast_membench.dart $1 $second_input >/dev/null 2>$second_output

bytes1=$(fgrep 'heap.old.used.max' $first_output | head -n1 | cut -d' ' -f4)
bytes2=$(fgrep 'heap.old.used.max' $second_output | head -n1 | cut -d' ' -f4)

bytes=$(echo "($bytes2 - $bytes1)/($second_input - $first_input)" | bc)
mega_bytes=$(echo "$bytes / 1000000" | bc)
printf "Memory usage = %d B (%2.2f MB)" $bytes $mega_bytes
echo

rm -f $first_output $second_output
