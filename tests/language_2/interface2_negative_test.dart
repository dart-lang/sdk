// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing wrong abstract class reference:
// A class must implement a known interface.

class Interface2NegativeTest implements BooHoo {
  static testMain() {}
}

main() {
  Interface2NegativeTest.testMain();
}
