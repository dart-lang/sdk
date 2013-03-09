// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing params.
//
// Contains test that is failing on dart2js. Merge this test with
// 'number_identity_test.dart' once fixed.

main() {
  for (int i = 0; i < 1000; i++) testNumberIdentity();
}


testNumberIdentity () {
  var a = double.NAN;
  var b = a + 0.0;
  Expect.isTrue(identical(a, b));
}
