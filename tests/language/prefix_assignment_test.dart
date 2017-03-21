// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Validate that assignment to a prefix is handled consistently with the
// following spec text from section 16.19 (Assignment):
//     Evaluation of an assignment a of the form v = e proceeds as follows:
//     Let d be the innermost declaration whose name is v or v=, if it exists.
//     It is a compile-time error if d denotes a prefix object.

import "empty_library.dart" as p;

class Base {
  var p;
}

class Derived extends Base {
  void f() {
    p = 1; //# 01: compile-time error
  }
}

main() {
  new Derived().f();
  p = 1; //# 02: compile-time error
}
