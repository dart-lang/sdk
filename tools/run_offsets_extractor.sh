#!/usr/bin/env bash
# Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

set -e

FILE="runtime/vm/compiler/runtime_offsets_extracted.h"

# Make sure we're running in the SDK directory.
if ! test -f "$FILE"; then
  echo "Couldn't find $FILE"
  echo "Make sure to run this script from the Dart SDK directory."
  exit 1
fi

TEMP="${FILE}.temp"
TEMP_HEADER="${FILE}.header.temp"
TEMP_JIT="${FILE}.jit.temp"
TEMP_AOT="${FILE}.aot.temp"

# Remove old temp files if the previous run was stopped prematurely.
rm -rf "${TEMP}" "${TEMP_HEADER}" "${TEMP_JIT}" "${TEMP_AOT}"

# We're regenerating the file, but we want to keep all the comments etc at the
# top of the file. So just delete everything after the first "#if defined".
LINE=$(grep "#if " "$FILE" -n | head -n 1 | sed "s/^\([0-9]*\):.*/\1/")
head -n $(expr $LINE - 1) "$FILE" >"$TEMP_HEADER"

# Run offsets_extractor for every architecture and append the results.
run() {
  tools/build.py --mode=$1 --arch=$2 offsets_extractor offsets_extractor_precompiled_runtime
  echo "" >>"$TEMP_JIT"
  out/$3/offsets_extractor >>"$TEMP_JIT"
  echo "" >>"$TEMP_AOT"
  out/$3/offsets_extractor_precompiled_runtime >>"$TEMP_AOT"
}
echo "" >>"$TEMP_JIT"
echo "" >>"$TEMP_AOT"
echo "#if !defined(PRODUCT)" >>"$TEMP_JIT"
echo "#if !defined(PRODUCT)" >>"$TEMP_AOT"
run release simarm ReleaseSIMARM
run release x64 ReleaseX64
run release ia32 ReleaseIA32
run release simarm64 ReleaseSIMARM64
echo "" >>"$TEMP_JIT"
echo "" >>"$TEMP_AOT"
echo "#else  // !defined(PRODUCT)" >>"$TEMP_JIT"
echo "#else  // !defined(PRODUCT)" >>"$TEMP_AOT"
run product simarm ProductSIMARM
run product x64 ProductX64
run product ia32 ProductIA32
run product simarm64 ProductSIMARM64
echo "" >>"$TEMP_JIT"
echo "" >>"$TEMP_AOT"
echo "#endif  // !defined(PRODUCT)" >>"$TEMP_JIT"
echo "#endif  // !defined(PRODUCT)" >>"$TEMP_AOT"

cat $TEMP_HEADER >>"$TEMP"
cat $TEMP_JIT >>"$TEMP"
cat $TEMP_AOT >>"$TEMP"

echo "" >>"$TEMP"
echo "#endif  // RUNTIME_VM_COMPILER_RUNTIME_OFFSETS_EXTRACTED_H_" >>"$TEMP"
mv "$TEMP" "$FILE"

# Cleanup.
git cl format "$FILE"
rm "$TEMP_HEADER"
rm "$TEMP_JIT"
rm "$TEMP_AOT"
echo -e "\n\nSuccessfully generated $FILE :)"
