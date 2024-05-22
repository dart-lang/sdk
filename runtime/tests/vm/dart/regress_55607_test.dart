// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that Dead Store Elimination (DSE) doesn't eliminate
// stores after incorrectly propagating "dead store" state beyond
// definition of instance and index of a store via loop backedge.
// Regression test for https://github.com/dart-lang/sdk/issues/55607.

import 'package:expect/expect.dart';

// Original example.
// Verifies that "dead store" state is not be propagated for indexed place
// 'part[offset]' beyond definition of index 'offset' which changes in a loop.
@pragma('vm:never-inline')
List<int> test1() {
  int offset = 0;
  List<int> part = [0, 0, 0];
  for (int i = 0; i < 2; i++) {
    part[offset] = 2;
    offset++;
  }
  part[offset] = 10;
  return part;
}

class A {
  int aField;
  A(this.aField);
  operator ==(Object other) => other is A && this.aField == other.aField;
  String toString() => 'A($aField)';
}

// Verifies that "dead store" state is not be propagated for instance field
// place 'obj.aField' beyond definition of instance 'obj' which changes in
// a loop.
@pragma('vm:never-inline')
List<A> test2() {
  A obj1 = A(0);
  A obj2 = A(0);
  final list = [obj1, obj2];
  A obj = obj1;
  for (int i = 0; i < 1; i++) {
    obj.aField = 2;
    obj = obj2;
  }
  obj.aField = 10;
  return list;
}

class B {
  A obj;
  B(this.obj);
  operator ==(Object other) => other is B && this.obj == other.obj;
  String toString() => 'B($obj)';
}

@pragma('vm:never-inline')
confuse(x) => x;

// Same as previous, but 'obj' definition is LoadField, not a Phi.
@pragma('vm:never-inline')
List<B> test3() {
  B b1 = confuse(B(A(0)));
  B b2 = confuse(B(A(0)));
  final list = [b1, b2];
  A obj;
  B bb = b1;
  for (int i = 0; (obj = bb.obj) != null && i < 1; i++) {
    obj.aField = 2;
    bb = b2;
  }
  obj.aField = 10;
  return list;
}

void main() {
  Expect.deepEquals([2, 2, 10], test1());
  Expect.deepEquals([A(2), A(10)], test2());
  Expect.deepEquals([B(A(2)), B(A(10))], test3());
}
