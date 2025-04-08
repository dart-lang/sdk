// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../common/testing.dart' as helper;
import 'package:expect/expect.dart';

import 'shared/shared.dart' show Base, Child1;

class Child extends Base {
  @override
  int method2() => 4;
}

/// A dynamic module is allowed to extend a class in the dynamic interface and
/// override its members.
///
/// This is similar to the `extend_class` test case, but includes more nuance,
/// like extending a non-leaf class that already was used in the program, since
/// that may affect dispatch logic based on some backends.
void main() async {
  Base o = Child1();
  Expect.equals(1, o.method1());
  Expect.equals(3, o.method2());
  Expect.equals(3, indirect(o));
  Expect.equals(4, indirect(Child()));
  o = (await helper.load('entry1.dart')) as Base;
  Expect.equals(1, o.method1());
  Expect.equals(2, o.method2());
  Expect.equals(2, indirect(o));
  helper.done();
}

@pragma('vm:never-inline')
int indirect(Base a) => a.method2();
