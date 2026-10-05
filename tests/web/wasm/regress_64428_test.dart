// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void foo({String s = 'hi'}) {
    print(s);
  }

  void call({String s = 'hi'}) {
    print(s);
  }
}

class B extends A {
  @override
  void foo({String s = 'there'}) {
    print(s);
  }

  @override
  void call({String s = 'there'}) {
    print(s);
  }
}

class C extends A {
  @override
  void foo({String s = 'world'}) {
    print(s);
  }
}

class HasGetter {
  dynamic get someDynamicMethod => () {};
}

A getBandC(int x) => x == 0 ? B() : C();
A getB(int x) => B();

void main() {
  // A is instantiated so it is not marked abstract by TFA, but A.foo and A.call
  // are never reachable on an instance of A so TFA removes their bodies and
  // parameter default values.
  print(A());

  getBandC(int.parse('0')).foo();
  getBandC(int.parse('1')).foo(s: 'wow');

  getB(int.parse('0')).call();
  getB(int.parse('1')).call(s: 'wow');
  dynamic d = int.parse('1') == 0 ? 1 : HasGetter();
  d.someDynamicMethod();
}
