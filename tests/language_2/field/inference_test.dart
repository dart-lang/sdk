// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js and its SsaConstructionFieldTypes
// phase.

import "package:expect/expect.dart";

class A {
  var _field;
  final other;
  get field => _field;
  A(this._field) : other = null;
  A.fromOther(this.other) {
    _field = other.field;
  }
}

class B {
  var a;
  B() {
    try {
      // Defeat inlining.
      // An inlined generative constructor call used to confuse
      // dart2js.
      a = new A(42);
    } catch (e) {
      rethrow;
    }
  }
}

var array = [new A(42), new B()];

main() {
  // Surround the call to [analyzeAfterB] by two [: new B() :] calls
  // to ensure the [B] constructor will be analyzed first.
  new B();
  var a = analyzeAfterB();
  new B();
  Expect.equals(42, a._field);
}

analyzeAfterB() {
  try {
    // Defeat inlining.
    return new A.fromOther(array[0]);
  } catch (e) {
    rethrow;
  }
}
