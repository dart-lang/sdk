// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class A1<X extends Function<T>()> {
  A1(Function<X extends Function<T>()>() f);
  bar1(Function<X extends Function<T>()>() f) {}
  Function<X extends Function<T>()>() bar2() => throw 42;
  Function<X extends Function<T>()>() get baz1 => throw 42;
  void set qux1(Function<X extends Function<T>()>() value) {}
  Function<X extends Function<T>()>() quux1 = throw 42;
  static Function<X extends Function<T>()>() quux2 = throw 42;
}

class A2<X extends void Function<Y extends Function<T>()>()> {}

class A3<
    X extends Function(void Function<Y extends Function(Function<T>())>())> {}

foo1(Function<X extends Function<T>()>() f) {}
foo2(Function<X extends Function(Function<T>())>() f) {}
Function<X extends Function<T>()>() foo3() => throw 42;
Function<X extends Function(Function<T>())>() foo4() => throw 42;
Function<X extends Function<T>()>() get corge1 => throw 42;
void set grault1(Function<X extends Function<T>()>() value) {}
Function<X extends Function<T>()>() quuz1 = throw 42;

typedef F1 = void Function<X extends void Function<T>()>();
typedef F2 = void Function<X extends Function(void Function<T>())>();
typedef F3<X extends Function<T>()> = Function();
typedef F4<X extends Function<Y extends Function<T>()>()> = Function();
typedef F5<X extends Function(Function<Y extends Function(Function<T>())>())>
    = Function();

class B1 {}

extension E1<X extends Function<T>()> on B1 {
  bar3(Function<X extends Function<T>()>() f) {}
  Function<X extends Function<T>()>() bar4() => throw 42;
  Function<X extends Function<T>()>() get baz2 => throw 42;
  void set qux2(Function<X extends Function<T>()>() value) {}
  static Function<X extends Function<T>()>() quux3 = throw 42;
}

main() {}
