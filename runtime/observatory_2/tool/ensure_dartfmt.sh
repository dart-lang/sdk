#!/bin/sh

dart_files=$(find lib web -name "*.dart")
[ -z "$dart_files" ] && exit 0

unformatted=$(dartfmt -n $dart_files)
[ -z "$unformatted" ] && exit 0

# Some files are not dartfmt'd. Print message and fail.
echo >&2 "dart files must be formatted with dartfmt. Please run:"
for fn in $unformatted; do
  echo >&2 "  dartfmt -w $PWD/$fn"
done

exit 1
