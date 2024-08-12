// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--no-strip-wasm --extra-compiler-option=-DTEST_COMPILATION_DIR=$TEST_COMPILATION_DIR

import 'source_map_simple_lib.dart' as Lib;

void main() {
  Lib.testMain('source_map_simple', frameDetails);
}

const List<(int?, int?)?> frameDetails = [
  (null, null), // _throwWithCurrentStackTrace
  (16, 3), // g
  (12, 3), // f
  (44, 5), // testMain
  (10, 7), // main
  null, // main tear-off, compiler generated, not mapped
  (null, null), // _invokeMain
];

/*
at Error._throwWithCurrentStackTrace (wasm://wasm/00119ad6:wasm-function[144]:0x165f1)
at g (wasm://wasm/00119ad6:wasm-function[1251]:0x2a8f6)
at f (wasm://wasm/00119ad6:wasm-function[809]:0x1f441)
at testMain (wasm://wasm/00119ad6:wasm-function[804]:0x1f0d4)
at main (wasm://wasm/00119ad6:wasm-function[801]:0x1f031)
at main tear-off trampoline (wasm://wasm/00119ad6:wasm-function[803]:0x1f044)
at _invokeMain (wasm://wasm/00119ad6:wasm-function[104]:0x1555b)
at Module.invoke (...)
*/
