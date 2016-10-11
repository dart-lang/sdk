// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Issue4157508Test {
  Issue4157508Test(var v) {
    var d = new DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
  }

  static void testMain() {
    var d = new Issue4157508Test(0);
  }
}

main() {
  Issue4157508Test.testMain();
}
