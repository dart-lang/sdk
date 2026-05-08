// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=-O4 --no-strip-wasm --extra-compiler-option=-DTEST_COMPILATION_DIR=$TEST_COMPILATION_DIR

import 'source_map_simple_lib.dart' as Lib;

void main() {
  Lib.testMain('source_map_simple_optimized', frameDetails);
}

const List<(String?, int?, int?, String?)?> frameDetails = [
  ('source_map_simple_lib.dart', 18, 3, 'g'),
  ('source_map_simple_lib.dart', 14, 3, 'f'),
];

/*
at $.Error._throwWithCurrentStackTrace (wasm://wasm/$-000861d2:wasm-function[52]:0xa834)
at $.g (wasm://wasm/$-000861d2:wasm-function[179]:0xcc8c)
at $._invokeMain (wasm://wasm/$-000861d2:wasm-function[49]:0x9fa0)
at InstantiatedApp.invokeMain (.../source_map_simple_optimized_test.mjs:354:37)
at main (.../run_wasm.js:428:21)
at async action (.../run_wasm.js:353:38)
at async eventLoop (.../run_wasm.js:329:9)
*/
