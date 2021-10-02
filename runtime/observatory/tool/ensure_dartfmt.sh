#!/bin/sh

dart_files=$(find lib web -name "*.dart")
[ -z "$dart_files" ] && exit 0

unformatted=$(dart format -o none $dart_files)
[ -z "$unformatted" ] && exit 0

# Some files are not dart formatted. Print message and fail.
echo >&2 "dart files must be formatted with dart format. Please run:"
for fn in $unformatted; do
  echo >&2 "  dart format $PWD/$fn"
done

exit 1
