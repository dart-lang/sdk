// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js bug 18257: Properly infer types for forwarding
// factory constructors with optional parameters with default values.

main() {
  A a = new A.a1();
  a.test();
}

class A {
  final bool condition;

  A({this.condition: true});

  factory A.a1({condition}) = _A1.boo;

  test() {
    if(condition != true) {
      throw "FAILED";
    } 
  }
}

class _A1 extends A {
  _A1.boo({condition: true}):
    super(condition: condition);
}

