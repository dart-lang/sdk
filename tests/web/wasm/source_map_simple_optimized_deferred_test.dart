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
  ('internal_patch.dart', 137, 17, '_invokeMain'),
];

/*
at $.Error._throwWithCurrentStackTrace (wasm://wasm/$-0009ed7a:wasm-function[57]:0xb2bb)
at $.g (wasm://wasm/$-0009ed7a:wasm-function[194]:0xe340)
at $.f (wasm://wasm/$-0009ed7a:wasm-function[193]:0xe334)
at $.main (wasm://wasm/$-0009ed7a:wasm-function[56]:0xa90c)
at $._invokeMain (wasm://wasm/$-0009ed7a:wasm-function[52]:0xa82c)
at InstantiatedApp.invokeMain (.../source_map_simple_optimized_deferred_test.mjs:413:37)
at main (.../run_wasm.js:428:21)
at async action (.../run_wasm.js:353:38)
*/
