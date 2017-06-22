// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_asserts_in_initializer_lists`

get tlg => null;
tlm() => null;

class A {
  var f;
  get g => null;
  m() => null;
  A.c1(a) {
    assert(a != null); // LINT
    assert(a != null); // LINT
  }
  // no more lint after non assert statement
  A.c2(a) {
    assert(a != null); // LINT
    assert(a != null); // LINT
    print('');
    assert(a != null); // OK
  }
  A.c3(a) {} // OK
  // still lint after unmovable assert
  A.c4(a) {
    assert(a != null); // LINT
    assert(this != null); // OK
    assert(a != null); // LINT
  }
  // no lint if this is used
  A.c5(a) {
    assert(this != null); // OK
  }
  // no lint if field is used
  A.c6(a) {
    assert(this.f != null); // OK
    assert(f != null); // OK
  }
  // no lint if method is used
  A.c7(a) {
    assert(this.m() != null); // OK
    assert(m() != null); // OK
  }
  // no lint if property access is used
  A.c8(a) {
    assert(this.g != null); // OK
    assert(g != null); // OK
  }
  // lint if method call is not on current object
  A.c9({f}) : f = f ?? 'f' {
    assert(f != null); // LINT
    assert(f.m1() != null); // LINT
    assert(f.m1().m2() != null); // LINT
  }
  A.c10({this.f}) {
    assert(f != null); // LINT
  }
  factory A.c11({f}) {
    assert(f != null); // OK
  }
  // lint for call of top level member
  A.c12() {
    assert(tlg != null); // LINT
    assert(tlm() != null); // LINT
  }

  // lint for call of static member
  static get sa => null;
  static sm() => null;
  A.c13() {
    assert(sa != null); // LINT
    assert(sm() != null); // LINT
  }

  A.c14() {
    assert(() // OK
        {
      f = true;
      return false;
    });
  }
}

// no lint for super class attributes
class B {
  var a;
  get b => null;
}

class C extends B {
  C() {
    assert(a != null); // OK
    assert(b != null); // OK
  }
}

// no lint for mixin attributes
class Mixin {
  var a;
}

class D extends Object with Mixin {
  D() {
    assert(a != null); // OK
  }
}

class E {
  set tlg(v) {}
  E() {
    // setter with the same name as top level getter used
    assert(tlg != null); // LINT
  }
}
