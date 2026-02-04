// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=-O4 --no-strip-wasm --enable-deferred-loading --extra-compiler-option=-DTEST_COMPILATION_DIR=$TEST_COMPILATION_DIR

import 'source_map_simple_lib.dart' as Lib;

void main() {
  Lib.testMain('source_map_simple_optimized_deferred', frameDetails);
}

const List<(String?, int?, int?, String?)?> frameDetails = [
  ('source_map_simple_lib.dart', 18, 3, 'g'),
  ('source_map_simple_lib.dart', 14, 3, 'f'),
  ('source_map_simple_lib.dart', 43, 5, 'testMain'),
];

/*
at <minified>.g (wasm://wasm/-000a82a6:wasm-function[193]:0xed1f)
at <minified>.f (wasm://wasm/-000a82a6:wasm-function[192]:0xed13)
at <minified>.main (wasm://wasm/-000a82a6:wasm-function[57]:0xb364)
at <minified>._invokeMain (wasm://wasm/-000a82a6:wasm-function[53]:0xb275)
at InstantiatedApp.invokeMain (.../source_map_simple_optimized_deferred_test.mjs:368:37)
at main (.../run_wasm.js:428:21)
at async action (.../run_wasm.js:353:38)
at async eventLoop (.../run_wasm.js:329:9)
*/
