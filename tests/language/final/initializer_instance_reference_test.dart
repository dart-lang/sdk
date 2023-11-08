// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart2js regression test. Error in initializer might be report with the wrong
// current element.

class C {
  const C();

  final x = 1;
  final y = x;
  //        ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] Can't access 'this' in a field initializer to read 'x'.
  // [cfe] Not a constant expression.
}

main() {
  const C().y;
}
