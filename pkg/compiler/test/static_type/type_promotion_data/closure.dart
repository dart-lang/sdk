// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  closure6(null);
  closure7();
}

class A {}

class B extends A {
  f() {}
}

_returnTrue(_) => true;

closure6(var x) {
  var closure;
  /*{}*/ x is B && _returnTrue(closure = () => /*{}*/ x.f());
  /*{}*/ x;
  x = new A();
  /*{}*/ closure();
  /*{}*/ x;
}

class C {}

class D extends C {
  f() {}
}

class E extends D {
  g() {}
}

_closure7(C x) {
  /*{}*/ x is D && _returnTrue((() => /*{}*/ x)())
      ? /*{x:[{true:D}|D]}*/ x.f()
      : x = new C();
  _returnTrue((() => /*{}*/ x)()) && /*{}*/ x is D
      ? /*{x:[{true:D}|D]}*/ x.f()
      : x = new C();

  (/*{}*/ x is D && _returnTrue((() => /*{}*/ x)())) &&
          (/*{x:[{true:D}|D]}*/ x is E && _returnTrue((() => /*{}*/ x)()))
      ? /*{x:[{true:D,E}|D,E]}*/ x.g()
      : x = new C();

  (_returnTrue((() => /*{}*/ x)()) && /*{}*/ x is E) &&
          (_returnTrue((() => /*{}*/ x)()) && /*{x:[{true:E}|E]}*/ x is D)
      ? /*{x:[{true:E,D}|E,D]}*/ x.g()
      : x = new C();
}

closure7() {
  _closure7(new D());
  _closure7(new E());
}
