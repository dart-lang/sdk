// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js, whose value range analysis phase
// assumed loop phis that were integer necessarily had integer inputs.

var array = const [0, 0.5];
var globalB = array[0];
var otherArray = [5];

main() {
  var b = globalB;
  var a = b + 1;
  if (otherArray[0] == 0) {
    // Use a non-existing selector to prevent adding a bailout check.
    (a as dynamic).noSuch();
    a = otherArray[0];
  }

  // Use [a] to make sure it does not become dead code.
  var f = array[a];

  // Add an integer check on [b].
  var d = array[b];

  // This instruction will be GVN to the same value as [a].
  // By being GVN'ed, [e] will have its type changed from integer
  // to number: because of the int type check on [b], we know
  // [: b + 1 :] returns an integer.
  // However we update this instruction with the previous [: b + 1 :]
  // that did not have that information and therefore only knows that
  // the instruction returns a number.
  var e = b + 1;

  // Introduce a loop phi that has [e] as header input, and [e++] as
  // update input. By having [e] as input, dart2js will compute an
  // integer type for the phi. However, after GVN, [e] becomes a
  // number.

  while (otherArray[0] == 0) {
    // Use [e] as an index for an array so that the value range
    // analysis tries to compute a range for [e].
    otherArray[e] = d + f;
    e++;
  }
}
