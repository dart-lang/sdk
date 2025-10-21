// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Invokes dart2wasm with various VM modes and flags, checking for crashes or
// differences in output compared to the default.

import "flag_fuzzer.dart";

main() => flagFuzz(
  (String output) => [
    "pkg/dart2wasm/bin/dart2wasm.dart",
    "--platform=out/ReleaseX64/dart2wasm_platform.dill",
    "--no-source-maps", // Otherwise output includes path
    "pkg/compiler/lib/src/util/memory_compiler.dart",
    output,
  ],
  "wasm",
);
