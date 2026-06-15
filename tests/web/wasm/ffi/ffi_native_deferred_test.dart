// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-ffi --enable-deferred-loading
// SharedObjects=ffi_native_test_module

import 'ffi_native_test.dart' deferred as D;

main() async {
  await D.loadLibrary();
  D.main();
}
