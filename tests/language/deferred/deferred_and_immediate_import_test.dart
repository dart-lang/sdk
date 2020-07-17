// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "deferred_and_immediate_import_lib.dart" as immediatePrefix;
import "deferred_and_immediate_import_lib.dart" deferred as deferredPrefix;

main() async {
  immediatePrefix.foo();

  Expect.throws(() {
    deferredPrefix.foo();
  });

  await deferredPrefix.loadLibrary();
  deferredPrefix.foo();
}
