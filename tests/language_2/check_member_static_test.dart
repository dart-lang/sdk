// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  static var a;
  var b;
}

class B extends A {}

class C extends B {
  var a; //# 01: compile-time error
  static var b; //# 02: compile-time error
}

void main() {
  new C();
}
