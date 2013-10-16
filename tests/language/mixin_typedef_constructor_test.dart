// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  var field;
  A(this.field);
}

class Mixin {
  var mixinField = 54;
}

class MyClass = A with Mixin;

main() {
  var a = new MyClass(42);
  Expect.equals(42, a.field);
  Expect.equals(54, a.mixinField);
}
