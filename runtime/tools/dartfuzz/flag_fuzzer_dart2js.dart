// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Invokes dart2js with various VM modes and flags, checking for crashes or
// differences in output compared to the default.

import "flag_fuzzer.dart";

main() => flagFuzz(
  (String output) => [
    "pkg/compiler/lib/src/dart2js.dart",
    "--invoker=test",
    "--platform-binaries=out/ReleaseX64",
    "--out=$output",
    "--no-source-maps", // Otherwise output includes path
    "pkg/compiler/lib/src/util/memory_compiler.dart",
  ],
  "js",
);
