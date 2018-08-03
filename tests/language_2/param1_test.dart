// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing params.

class Param1Test {
  // TODO(asiva): Should we try to interpret 1 above as an int? In order to
  // avoid a type error with --enable_type_checks, the type of i below is
  // changed from int to String.
  // static int testMain(String s, int i) { return i; }
  static int testMain() {
    return 0;
  }
}

main() {
  Param1Test.testMain();
}
