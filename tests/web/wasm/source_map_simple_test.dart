// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--no-strip-wasm --extra-compiler-option=-DTEST_COMPILATION_DIR=$TEST_COMPILATION_DIR

import 'source_map_simple_lib.dart' as Lib;

void main() {
  Lib.testMain('source_map_simple', frameDetails);
}

const List<(String?, int?, int?, String?)?> frameDetails = [
  ('errors_patch.dart', 20, 39, '_throwWithCurrentStackTrace'),
  ('source_map_simple_lib.dart', 18, 3, 'g'),
  ('source_map_simple_lib.dart', 14, 3, 'f'),
  ('source_map_simple_lib.dart', 43, 5, 'testMain'),
  ('source_map_simple_test.dart', 10, 7, 'main'),
  ('internal_patch.dart', 126, 13, '_invokeMainArg0'),
  null,
  ('internal_patch.dart', 160, 5, '_invokeMain'),
];

/*
    at module0.Error._throwWithCurrentStackTrace <noInline> (wasm://wasm/module0-00110126:wasm-function[108]:0xfd1c)
    at module0.g (wasm://wasm/module0-00110126:wasm-function[254]:0x11a8e)
    at module0.f (wasm://wasm/module0-00110126:wasm-function[251]:0x11a64)
    at module0.testMain (wasm://wasm/module0-00110126:wasm-function[249]:0x115d0)
    at module0.main (wasm://wasm/module0-00110126:wasm-function[248]:0x1154b)
    at module0._invokeMainArg0 (wasm://wasm/module0-00110126:wasm-function[247]:0x11541)
    at module0._invokeMainInternal (wasm://wasm/module0-00110126:wasm-function[82]:0xf8b2)
    at module0._invokeMain (wasm://wasm/module0-00110126:wasm-function[77]:0xf815)
*/
