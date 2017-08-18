// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that we can use pseudo keywords as names in function level code.

import "package:expect/expect.dart";

class PseudoKWTest {
  static testMain() {
    // This is a list of built-in identifiers from the Dart spec.
    // It sanity checks that these pseudo-keywords are legal identifiers.

    var abstract = 0; //# 01: ok
    var as = 0;
    var dynamic = 0;
    var export = 0;
    var external = 0; //# 01: ok
    var factory = 0;
    var get = 0;
    var implements = 0;
    var import = 0;
    var library = 0;
    var operator = 0;
    var part = 0;
    var set = 0;
    var static = 0; //# 01: ok
    var typedef = 0;

    // "native" is a per-implementation extension that is not a part of the
    // Dart language.  While it is not an official built-in identifier, it
    // is useful to ensure that it remains a legal identifier.
    var native = 0;

    // The code below adds a few additional variants of usage without any
    // attempt at complete coverage.
    {
      void factory(set) {
        return; //# 01: ok
      }
    }

    get:
    while (import > 0) {
      break get;
    }

    return
        static + //# 01: ok
        library * operator;
  }
}

typedef(x) => "typedef $x"; //# 01: ok

static(abstract) { //# 01: ok
  return abstract == true; //# 01: ok
} //# 01: ok

class A {
  var typedef = 0;
  final operator = "smooth";

  set(x) {
    typedef = x;
  }

  get() => typedef - 5;

  static static() { //# 01: ok
    return 1; //# 01: ok
  } //# 01: ok
  static check() {
    var o = new A();
    o.set(55);
    Expect.equals(50, o.get());
    static(); //# 01: ok
  }
}

class B {
  var set = 100;
  get get => set;
  set get(get) => set = 2 * get.get;

  static() { //# 01: ok
    var set = new B(); //# 01: ok
    set.get = set; //# 01: ok
    Expect.equals(200, set.get); //# 01: ok
  } //# 01: ok
  int operator() {
    return 1;
  }
}

class C {
  static int operator = (5);
  static var get;
  static get set => 111;
  static set set(set) {}
}

main() {
  PseudoKWTest.testMain();
  A.check();
  new B().static(); //# 01: ok
  Expect.equals(1, new B().operator());
  Expect.equals(1, A.static()); //# 01: ok
  typedef("T"); //# 01: ok
  Expect.equals("typedef T", typedef("T")); //# 01: ok
  static("true"); //# 01: ok
  Expect.equals(false, static("true")); //# 01: ok
  Expect.equals(5, C.operator);
  Expect.equals(null, C.get);
  C.set = 0;
  Expect.equals(111, C.set);
}
