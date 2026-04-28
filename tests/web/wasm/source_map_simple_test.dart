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
  ('invoke_main_patch.dart', 12, 13, '_invokeMainArg0'),
  null,
  ('invoke_main_patch.dart', 46, 5, '_invokeMain'),
];

/*
    at module0.Error._throwWithCurrentStackTrace <noInline> (wasm://wasm/module0-0010c51a:wasm-function[106]:0xf8c1)
    at module0.g (wasm://wasm/module0-0010c51a:wasm-function[254]:0x11767)
    at module0.f (wasm://wasm/module0-0010c51a:wasm-function[251]:0x1173d)
    at module0.testMain (wasm://wasm/module0-0010c51a:wasm-function[249]:0x112aa)
    at module0.main (wasm://wasm/module0-0010c51a:wasm-function[248]:0x11226)
    at module0._invokeMainArg0 (wasm://wasm/module0-0010c51a:wasm-function[247]:0x1121c)
    at module0._invokeMainInternal (wasm://wasm/module0-0010c51a:wasm-function[81]:0xf50f)
    at module0._invokeMain (wasm://wasm/module0-0010c51a:wasm-function[76]:0xf476)
*/
