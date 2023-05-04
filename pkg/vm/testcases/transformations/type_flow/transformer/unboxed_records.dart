// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool condition = int.parse('1') == 1;

dynamic returnUnboxed1() => (1, 2);
dynamic returnUnboxed2() =>
    condition ? (int.parse('1'), 42) : (2, int.parse('43'));
dynamic returnUnboxed3() => (foo: 'foo', bar: 3.14);
dynamic get returnUnboxed4 => returnUnboxed3();

dynamic returnBoxed1() => condition ? (int.parse('1'), 42) : null;
dynamic returnBoxed2() => condition ? (int.parse('1'), 42) : 42;

@pragma('vm:entry-point')
dynamic returnBoxed3() => (1, 2);

abstract class A {
  dynamic returnUnboxed1();
  dynamic get returnUnboxed2;

  dynamic returnBoxed1();
  dynamic get returnBoxed2;
}

class B implements A {
  dynamic returnUnboxed1() => (1.0, 'hey');
  dynamic get returnUnboxed2 => (foo: 'hi', int.parse('2'));

  dynamic returnBoxed1() => (1.0, 'hey');
  dynamic get returnBoxed2 => (foo: 'hi', int.parse('2'));
}

class C extends A {
  dynamic returnUnboxed1() => ('bye', 10);
  dynamic get returnUnboxed2 => (foo: 3.14, int.parse('3'));

  dynamic returnBoxed1() => (1.0, 'hey', 3);
  dynamic get returnBoxed2 => (bar: 'hi', int.parse('2'));
}

main() {
  print(returnUnboxed1());
  print(returnUnboxed2());
  print(returnUnboxed3());
  print(returnUnboxed4);

  print(returnBoxed1());
  print(returnBoxed2());
  print(returnBoxed3());

  A obj = condition ? B() : C();
  print(obj.returnUnboxed1());
  print(obj.returnUnboxed2);
  print(obj.returnBoxed1());
  print(obj.returnBoxed2);
}
