// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'unboxed_parameter_helper.dart';

abstract class I {
  int get value;
  int getValue();
}

class Foo implements I {
  int value;
  Foo(this.value);
  int getValue() => value;
}

class Bar implements I {
  int get value => integerFieldValue;
  int getValue() => value;
}

final objects = <dynamic>[Foo(integerFieldValue), Bar()];
final tearoffs = <dynamic>[Foo(integerFieldValue).getValue, Bar().getValue];

main() {
  // Dynamic accesses to getter, method and tear-off
  Expect.equals(objects[0].value, integerFieldValue);
  Expect.equals(objects[0].getValue(), integerFieldValue);
  Expect.equals(objects[1].value, integerFieldValue);
  Expect.equals(objects[1].getValue(), integerFieldValue);
  Expect.equals(tearoffs[0](), integerFieldValue);
  Expect.equals(tearoffs[1](), integerFieldValue);

  // Interface-based accesses to getter, method and tear-off
  final Foo foo = objects[0] as Foo;
  final int Function() fooGetValue = foo.getValue;
  Expect.equals(foo.value, integerFieldValue);
  Expect.equals(foo.getValue(), integerFieldValue);
  Expect.equals(fooGetValue(), integerFieldValue);

  final Bar bar = objects[1] as Bar;
  final int Function() barGetValue = bar.getValue;
  Expect.equals(bar.value, integerFieldValue);
  Expect.equals(bar.getValue(), integerFieldValue);
  Expect.equals(barGetValue(), integerFieldValue);
}
