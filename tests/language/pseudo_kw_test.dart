// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that we can use pseudo keywords as names in function level code.


class PseudoKWTest {
  static testMain() {

    // This is a list of built-in identifiers from the Dart spec.
    // It sanity checks that these pseudo-keywords are legal identifiers.

    var abstract = 0;
    var assert = 0;
    var call = 0;
    var Dynamic = 0;
    var factory = 0;
    var get = 0;
    var implements = 0;
    var import = 0;
    var interface = 0;
    var library = 0;
    var negate = 0;
    var operator = 0;
    var set = 0;
    var source = 0;
    var static = 0;
    var typedef = 0;

    // "native" is a per-implementation extension that is not a part of the
    // Dart language.  While it is not an official built-in identifier, it
    // is useful to ensure that it remains a legal identifier.
    var native = 0;


    // The code below adds a few additional variants of usage without any
    // attempt at complete coverage.
    {
      void factory(set) {
        return 0;
      }
    }

    get: while (import > 0) {
      break get;
    }

    return static + library * operator;
  }
}

typedef(x) => "typedef $x";

static(abstract) {
  return abstract == true;
}

class A {
  var typedef = 0;
  final operator = "smooth";

  set(x) { typedef = x; }
  get() => typedef - 5;

  static static() {
    return 1;
  }
  static check() {
    var o = new A();
    o.set(55);
    Expect.equals(50, o.get());
    static();
  }
}

class B {
  var set = 100;
  get get() => set;
  set get(get) => set = 2 * get.get;

  static() {
    var set = new B();
    set.get = set;
    Expect.equals(200, set.get);
  }
  int operator() {
    return 1;
  }
}

class C {
  static int operator = (5);
  static var get;
  static get set() => 111;
  static set set(set) { }
}


main() {
  PseudoKWTest.testMain();
  A.check();
  new B().static();
  Expect.equals(1, new B().operator());
  Expect.equals(1, A.static());
  typedef("T");
  Expect.equals("typedef T", typedef("T"));
  static("true");
  Expect.equals(false, static("true"));
  Expect.equals(5, C.operator);
  Expect.equals(null, C.get);
  C.set = 0;
  Expect.equals(111, C.set);
}
