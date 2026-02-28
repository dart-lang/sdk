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
  ('internal_patch.dart', 137, 17, '_invokeMain'),
];

/*
at module0.Error._throwWithCurrentStackTrace (wasm://wasm/module0-0012402a:wasm-function[132]:0x11274)
at module0.g (wasm://wasm/module0-0012402a:wasm-function[473]:0x15b7f)
at module0.f (wasm://wasm/module0-0012402a:wasm-function[471]:0x15b6d)
at module0.testMain (wasm://wasm/module0-0012402a:wasm-function[470]:0x158aa)
at module0.main (wasm://wasm/module0-0012402a:wasm-function[131]:0x11269)
at module0._invokeMain (wasm://wasm/module0-0012402a:wasm-function[124]:0x111bc)
*/
