// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// dart2wasmOptions=--enable-deferred-loading

import 'deferred_constant_use_under_load_guard_def.dart' deferred as D;

main() async {
  await D.loadLibrary();
  await D.runTest();
}
