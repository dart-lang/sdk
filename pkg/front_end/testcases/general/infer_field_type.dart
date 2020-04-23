// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C extends B {
  var field;
}

class B extends A {
  get field => null;
  set field(value) {}
}

class A {
  var field = 0;
}

var topLevelFieldFromA = new A().field;
var topLevelFieldFromB = new B().field;
var topLevelFieldFromC = new C().field;

main() {}
