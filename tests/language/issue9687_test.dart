// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js code generation in checked mode. See
// last part of https://code.google.com/p/dart/issues/detail?id=9687.

import "package:expect/expect.dart";

class A {
  final finalField;
  final otherFinalField;

  A()
      : finalField = 42,
        otherFinalField = 54;

  expectFinalField(arg1, arg2) {
    Expect.equals(arg1, arg2);
    Expect.equals(finalField, arg1);
  }

  expectOtherFinalField(_, arg1, arg2) {
    Expect.equals(arg1, arg2);
    Expect.equals(otherFinalField, arg1);
  }
}

var array = [new A()];

main() {
  // [untypedReceiver] is made so that the compiler does not know
  // what it is.
  var untypedReceiver = array[0];

  // [typedReceiver] is made so that the compiler knows what it is.
  var typedReceiver = new A();

  // Using [: finalField :] twice will make the compiler want to
  // allocate one temporary for it.
  var a = untypedReceiver.expectFinalField(
      typedReceiver.finalField, typedReceiver.finalField);

  // Having a check instruction in between two allocations of
  // temporary variables used to trigger a bug in the compiler.
  int b = a;

  // Using [: otherFinalField :] twice will make the compiler want to
  // allocate one temporary for it. The compiler used to assign the
  // same temporary for [: otherFinalField :] and [: finalField :].
  untypedReceiver.expectOtherFinalField(
      b, typedReceiver.otherFinalField, typedReceiver.otherFinalField);
}
