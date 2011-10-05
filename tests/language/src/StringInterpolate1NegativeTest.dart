// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing that the interpolated identifier does not start
// with '$'.

class StringInterpolate1NegativeTest {

  static testMain() {
    var $x = 1;
    var s = "eins und $$x macht zwei.";
    print(s);
  }

}

main() {
  StringInterpolate1NegativeTest.testMain();
}
