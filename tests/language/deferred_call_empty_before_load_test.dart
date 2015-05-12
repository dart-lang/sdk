// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that calling a function, even though it itself has no effect, will
// trigger an error if the corresponding deferred library has not been loaded.

import "package:expect/expect.dart";
import "deferred_call_empty_before_load_lib.dart" deferred as lib1;

main() {
  Expect.throws(() => lib1.thefun());
}
