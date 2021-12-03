// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Verifies that unboxing info is attached to a member with unreachable body,
// which is still used as an interface target.
// Regression test for https://github.com/dart-lang/sdk/issues/44563.

import 'package:expect/expect.dart';

class BaseClass {
  int get value => 0;
}

class Class1 extends BaseClass {
  @pragma('vm:never-inline')
  int get value => 1;
}

class Class2 extends BaseClass {
  @pragma('vm:never-inline')
  int get value => 2;
}

bool nonConstantCondition = int.parse("1") == 1;

void main() {
  BaseClass obj = BaseClass();
  obj = nonConstantCondition ? Class1() : Class2();
  Expect.equals(1, obj.value);
}
