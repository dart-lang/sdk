// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** A function that accepts 0..2 arguments and records calls. */
void poly([a, b]) {
  polyCount++;
  polyArg = a;
}

/** First argument of most recent call to [poly]. */
var polyArg = 0;

/** Number of calls to [poly]. */
var polyCount = 0;

// Four (Super)classes that declare an "assert" member.

class SuperGet {
  /** Declare "assert" as a getter. */
  get assert => poly;

  /**
    * A method that shold see an 'assert' declaration in scope and not
    * not act as an assertion.
    */
  void lexicalAssert(x) {
    assert(x);
  }
}

class SuperMethod {
  /** Declare "assert" as a method. */
  assert([a, b]) => poly(a, b);

  void lexicalAssert(x) {
    assert(x);
  }
}

class SuperField {
  /** Declare "assert" as a field. */
  var assert;
  SuperField() : assert = poly;

  void lexicalAssert(x) {
    assert(x);
  }
}

class SuperNon {
  /** Implementation of "assert" calls on this. */
  noSuchMethod(x, y) {
    switch (y.length) {
      case 0: return poly();
      case 1: return poly(y[0]);
      case 2: return poly(y[0], y[1]);
    }
  }

  void lexicalAssert(x) {
    // Hack, since there is no lexically enclosing 'assert' declaration here,
    // so just act as if there was to avoid special casing it in the test.
    poly(x);
  }
}

// Corresponding sub-classes that read/call "assert" in different ways.
// In every case except "assert(exp);" (in the "assert1" methods) this should
// access the superclass member.

class SubGet extends SuperGet {
  /** Read assert as a variable. */
  void getAssert(x) {
    assert;
  }
  /** Call "assert" with zero arguments. */
  void assert0(x) {
    assert();
  }
  /** Make an actual assertion. */
  void assert1(x) {
    assert(x);
  }
  /** Call "assert" with one argument in expression context. */
  void assertExp(x) {
    var z = assert(x);
  }
  /** Call "assert" with two arguments. */
  void assert2(x) {
    assert(x, x);
  }
}

class SubMethod extends SuperMethod {
  void getAssert(x) {
    assert;
  }
  void assert0(x) {
    assert();
  }
  void assert1(x) {
    assert(x);
  }
  void assertExp(x) {
    var z = assert(x);
  }
  void assert2(x) {
    assert(x, x);
  }
}

class SubField extends SuperField {
  void getAssert(x) {
    assert;
  }
  void assert0(x) {
    assert();
  }
  void assert1(x) {
    assert(x);
  }
  void assertExp(x) {
    var z = assert(x);
  }
  void assert2(x) {
    assert(x, x);
  }
}

class SubNon extends SuperNon {
  void getAssert(x) {
    assert;
  }
  assert0(x) {
    assert();
  }
  void assert1(x) {
    assert(x);
  }
  void assertExp(x) {
    var z = assert(x);
  }
  void assert2(x) {
    assert(x, x);
  }
}


testAssertDeclared() {
  var get = new SubGet();
  var method = new SubMethod();
  var field = new SubField();
  var non = new SubNon();

  void expectCallsPoly(code, [bool noArgument = false]) {
    int oldPolyCount = polyCount;
    int newPolyArg = polyArg + 1;
    int expectedPolyArg = noArgument ? null : newPolyArg;
    code(newPolyArg);
    Expect.equals(oldPolyCount + 1, polyCount);
    Expect.equals(expectedPolyArg, polyArg);
    if (noArgument) polyArg = newPolyArg;
  }

  void expectAssert(code) {
    int oldPolyCount = polyCount;
    // Detect whether asserts are enabled.
    bool assertsEnabled = false;
    assert(assertsEnabled = true);
    try {
      code(polyArg + 1);
      // If asserts are enabled, we should not get here.
      // If they are not, the call does nothing.
      if (assertsEnabled) {
        Expect.fail("Didn't call assert with asserts enabled.");
      }
    } on AssertionError catch (e) {
      if (!assertsEnabled) Expect.fail("Called assert with asserts disabled?");
    }
    Expect.equals(oldPolyCount, polyCount);
  }

  // Sanity check.
  expectCallsPoly(poly);

  // Doesn't fail to read "assert".
  get.getAssert(0);
  method.getAssert(0);
  field.getAssert(0);
  expectCallsPoly(non.getAssert, true);  // Hits 'noSuchMethod' for the getter.

  // Check when 'assert' is a superclass member declaration (or, simulated with
  // noSuchMethod).
  void testSuperAssert(object) {
    expectCallsPoly(object.assert0, true);
    expectAssert(object.assert1);
    expectCallsPoly(object.assertExp);
    expectCallsPoly(object.assert2);
    expectCallsPoly(object.lexicalAssert);
  }

  testSuperAssert(get);
  testSuperAssert(method);
  testSuperAssert(field);
  testSuperAssert(non);

  // A local declaration will inhibit assert-behavior.

  expectCallsPoly((x) {
    // Declare "assert" as a local variable.
    var assert = poly;
    assert(x);
  });

  expectCallsPoly((x) {
    // Declare "assert" as a local function.
    void assert(x) => poly(x);
    assert(x);
  });
}

main() {
  testAssertDeclared();
}
