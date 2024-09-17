// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=-O4 --no-strip-wasm --extra-compiler-option=-DTEST_COMPILATION_DIR=$TEST_COMPILATION_DIR

import 'source_map_simple_lib.dart' as Lib;

void main() {
  Lib.testMain('source_map_simple_optimized', frameDetails);
}

const List<(String?, int?, int?)?> frameDetails = [
  ('errors_patch.dart', null, null), // _throwWithCurrentStackTrace
  ('source_map_simple_lib.dart', 16, 3), // g
  ('source_map_simple_lib.dart', 12, 3), // f
  ('source_map_simple_lib.dart', 38, 5), // testMain, inlined in main
  ('internal_patch.dart', null, null), // _invokeMain
];

/*
at Error._throwWithCurrentStackTrace (wasm://wasm/0008d08e:wasm-function[115]:0xc095)
at g (wasm://wasm/0008d08e:wasm-function[359]:0x11e15)
at f (wasm://wasm/0008d08e:wasm-function[358]:0x11e0b)
at main (wasm://wasm/0008d08e:wasm-function[357]:0x11913)
at _invokeMain (wasm://wasm/0008d08e:wasm-function[82]:0xb349)
at Module.invoke (...)
at main (...)
at async action (...)
*/
