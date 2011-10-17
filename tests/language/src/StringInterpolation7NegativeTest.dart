// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Disallow assignment of string interpolation to a static final field

class A {
  static final x = 1;
  static final y = "Two is greater than ${x}";  // ERROR: String interpolation
}

main() {
  var a = A.y;
}
