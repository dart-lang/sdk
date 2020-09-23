// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/// Test that variables which are initialized to Null are inferred at type
/// `dynamic`.

var global0 = null;
var global1 = null as Null;

class Test {
  static var static0 = null;
  static var static1 = null as Null;

  var instance0 = null;
  var instance1 = null as Null;
}

/// For each category of variable and each style of initialization, we test that
/// the variable verify that the type is not `Never` by verifying that a value
/// of type `Object` may be assigned to it, and then check that the type is
/// `dynamic` (or `Never` which has been eliminated) by verifying that an
/// arbitrary method may be called on it.

void test() {
  final Object three = 3;
  {
    global0 = three;
    Expect.isFalse(global0.isEven);
    global1 = three;
    Expect.isFalse(global1.isEven);
  }
  {
    Test.static0 = three;
    Expect.isFalse(Test.static0.isEven);
    Test.static1 = three;
    Expect.isFalse(Test.static1.isEven);
  }
  {
    var o = new Test();
    o.instance0 = three;
    Expect.isFalse(o.instance0.isEven);
    o.instance1 = three;
    Expect.isFalse(o.instance1.isEven);
  }
  {
    var local0 = null;
    var local1 = null as Null;

    local0 = three;
    Expect.isFalse(local0.isEven);
    local1 = three;
    Expect.isFalse(local1.isEven);
  }
}

void main() {
  test();
}
