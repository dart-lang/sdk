// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart version of two-argument Ackermann-Peter function.

import "package:expect/expect.dart";

main() {
  try {
    print("abcdef".substring(1.5, 3.5)); //   //# 01: compile-time error
    Expect.fail("Should have thrown an exception"); // //# 01: continued
  } on TypeError catch (e) {
    // OK.
  } on ArgumentError catch (e) {
    // OK.
  }
}
