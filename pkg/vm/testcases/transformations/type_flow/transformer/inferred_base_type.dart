// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Base {
  int foo();
}

class Sub1 extends Base {
  @override
  int foo() => 1;
}

class Sub2 extends Base {
  @override
  int foo() => 2;
}

class GenericBox<T extends num> {
  final T value;
  GenericBox(this.value);
}

class Foo {}

Object field = int.parse('1') == 1 ? Sub1() : Sub2();

Object returnBase(bool cond) => cond ? Sub1() : Sub2();

Object returnGenericBox(bool cond) =>
    cond ? GenericBox<int>(1) : GenericBox<double>(2.0);

List<Foo> returnFixedLengthList(bool c1, bool c2, bool c3, bool c4) => c1
    ? const <Foo>[]
    : (c2
          ? List<Foo>.generate(2, (_) => Foo(), growable: false)
          : (c3
                ? List<Foo>.filled(2, Foo(), growable: false)
                : (c4
                      ? List<Foo>.of(<Foo>[Foo()], growable: false)
                      : List<Foo>.unmodifiableOf(<Foo>[Foo()]))));

void useBase(Object arg) {
  if (arg is Base) {
    print(arg.foo());
  }
}

void main() {
  final cond = int.parse('1') == 1;
  useBase(field);
  useBase(returnBase(cond));
  print(returnGenericBox(cond));
  print(returnFixedLengthList(cond, !cond, cond, !cond));
}
