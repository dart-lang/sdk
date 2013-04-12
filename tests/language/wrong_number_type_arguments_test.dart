// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Map takes 2 type arguments.
Map
<String> /// 00: static type warning
foo;
Map
<String> /// 02: static type warning
baz;

main() {
  foo = null;
  var bar = new Map
  <String> /// 01: compile-time error
  ();
  testNonNullAssignment(); /// 02: continued
}

isCheckedMode() {
  try {
    var i = 1;
    String s = i;
    return false;
  } catch (e) {
    return true;
  }
}

void testNonNullAssignment() {
  bool got_type_error = false;
  try {
    baz = new Map();
  } on TypeError catch (error) {
    print(error);
    got_type_error = true;
  }
  // Type error in checked mode only.
  Expect.isTrue(got_type_error == isCheckedMode());
}
