// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Map takes 2 type arguments.
Map
    <String> //# 00: compile-time error
foo;
Map
    <String> //# 02: compile-time error
baz;

main() {
  foo = null; //# 00: continued
  var bar = new Map
      <String> //# 01: compile-time error
    ();
  baz = new Map(); //# 02: continued
}
