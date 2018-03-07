// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class T1 {}

class T2 {}

class T3 {}

class T4 {}

class T5 {}

class T6 {}

class T7 {}

abstract class A {
  foo();
  get bar;
  bazz(a1, a2, a3, [a4, a5]);
}

class B extends A {
  noSuchMethod(Invocation invocation) {
    return new T1();
  }
}

class C {
  noSuchMethod(Invocation invocation) {
    return new T2();
  }
}

class D extends C implements A {}

class E implements A {
  foo() => new T3();

  noSuchMethod(Invocation invocation) {
    return new T4();
  }
}

class F {
  twoArg(a1, a2) => new T1();

  noSuchMethod(Invocation invocation) {
    return new T2();
  }
}

class G {
  noSuchMethod(Invocation invocation) {
    return new T5();
  }
}

class H {
  foo({left, right}) => new T6();

  noSuchMethod(Invocation invocation) {
    return new T7();
  }
}

A bb = new B();
A dd = new D();

Function unknown;

getDynamic() => unknown.call();

main(List<String> args) {
  print(bb.foo());
  print(bb.bar);
  print(bb.bazz(1, 2, 3, 4));

  print(dd.foo());
  print(dd.bar);
  print(dd.bazz(1, 2, 3, 4));

  new E();
  A xx = getDynamic();

  print(xx.bar);

  dynamic yy = getDynamic();
  print(yy.twoArg(1, 2, 3));

  new F();

  dynamic gg = new G();

  print(gg.noSuchMethod(null, null));

  dynamic hh = new H();

  print(hh.foo(right: 2, left: 1));
  print(hh.foo(left: 1, top: 2));
}
