// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to generate bad code for the
// non-bailout version of [main].

var a = [
  false,
  [1, 2, 3]
];
var b;

main() {
  // Defeat type inferencing for [b].
  b = new Object();
  b = 42;
  b = [];

  // Make the function recursive to force a bailout version.
  if (a[0]) main();

  // We used to ask [b] to be of the same type as [a], but not
  // checking that the length and element type are the same.
  var arrayPhi = a[0] ? a : b;

  if (arrayPhi.length != 0) {
    throw 'Test failed';
  }
}
