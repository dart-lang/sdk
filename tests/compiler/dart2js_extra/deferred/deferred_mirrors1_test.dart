// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

@MirrorsUsed(override: '*')
import 'dart:mirrors';

import 'deferred_mirrors1_lib.dart' deferred as lazy;

main() {
  asyncStart();

  // The deferred library uses mirrors and has an unused import of typed_data.
  // Dart2js must not crash on this test.
  //
  // Dart2js used to crash because:
  // - the NativeInt8List was dragged in.
  // - but not its constructors and the constructors' dependencies.
  // - one of the dependencies (a local function "_ensureNativeList") was
  //   not handled by the deferred-loader.
  lazy.loadLibrary().then((_) {
    Expect.equals(499, lazy.foo());
    asyncEnd();
  });
}
