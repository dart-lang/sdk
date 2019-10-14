// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N always_declare_return_types`

main() { } //LINT

bar() => new _Foo(); //LINT

class _Foo {
  _foo() => 42; //LINT
}

typedef bad(int x); //LINT

typedef bool predicate(Object o);

void main2() { }

_Foo bar2() => new _Foo();

class _Foo2 {
  int _foo() => 42;
}

set speed(int ms) {} //OK

class Car {
  static set make(String name) {} // OK
  set speed(int ms) {} //OK
}

abstract class MyList<E> extends List<E> {
  @override
  operator []=(int index, E value) //OK: #300
  {
    // ignored.
  }
}

class A { }

extension Foo on A {
  foo() { } // LINT
}
