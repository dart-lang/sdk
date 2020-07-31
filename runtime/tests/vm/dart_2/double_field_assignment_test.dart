// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

final bool alwaysTrue = int.parse('1') == 1;

abstract class I {
  double get val;
  void set val(double v);
}

class Foo implements I {
  double val;
  @pragma('vm:never-inline')
  Foo(this.val);
}

class Bar implements I {
  double val = alwaysTrue ? 1.1 : 2.2;
}

@pragma('vm:never-inline')
double identity(double x) => x;

@pragma('vm:never-inline')
void testGetter() {
  final I a = alwaysTrue ? Foo(4.2) : Bar();

  // Call intrinsic getter (which should make a copy if field is unboxed)
  final value = a.val;
  final valueAlias = identity(value);

  if (a is Foo) {
    // Override the mutable box via direct StoreInstanceField instruction.
    a.val = 99.0;
  }

  // Ensure value (aka valueAlias) was not overriden with 99.0
  Expect.equals(4.2, valueAlias);
}

@pragma('vm:never-inline')
void testSetter() {
  final I a = alwaysTrue ? Foo(1.0) : Bar();

  final value = alwaysTrue ? 4.2 : 2.1;
  final valueAlias = identity(value);

  // Call intrinsic setter (which should make a copy if field is unboxed)
  a.val = value;
  if (a is Foo) {
    // Override the mutable box via direct StoreInstanceField instruction.
    a.val = 99.0;
  }

  // Ensure value (aka valueAlias) was not overriden with 99.0
  Expect.equals(4.2, valueAlias);
}

main() {
  testGetter();
  testSetter();
}
