// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/47425.
// Verifies that Type.operator== works on generic types which
// classes are not finalized.

import 'package:expect/expect.dart';

void testTypesEquality<A, B>(bool expected) {
  Expect.equals(expected, A == B);
}

void withNewBox() {
  Box();
  testTypesEquality<Box<num>, Box<int>>(false);
}

void withoutNewBox() {
  testTypesEquality<Box<num>, Box<int>>(false);
}

class Box<T> {}

void main() {
  testTypesEquality<num, int>(false);
  testTypesEquality<Box<num>, Box<int>>(false);
  testTypesEquality<Box<num>, Box<num>>(true);

  withoutNewBox();
  withNewBox();
  withoutNewBox();

  testTypesEquality<Box<num>, Box<int>>(false);
  testTypesEquality<Box<num>, Box<num>>(true);
}
