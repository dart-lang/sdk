// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Only 'lib' imports mirrors.
// Function.apply is resolved, before it is known that mirrors are used.
// Dart2js has different implementations of Function.apply for different
// emitters (like --fast-startup). Dart2js must not switch the resolved
// Function.apply when it discovers the use of mirrors.
// In particular it must not switch from the fast-startup emitter to the full
// emitter without updating the Function.apply reference.
import 'function_apply_mirrors_lib.dart' as lib;

import "package:expect/expect.dart";

int foo({x: 499, y: 42}) => x + y;

main() {
  Expect.equals(709, Function.apply(foo, [], {#y: 210}));
  Expect.equals(499, lib.bar());
}
