// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C {
  foo() => 123;
}

main() {
  var f = new C().foo;
  var target = f.target; //# 01: compile-time error
  var self = f.self; //# 02: compile-time error
  var receiver = f.receiver; //# 03: compile-time error
}
