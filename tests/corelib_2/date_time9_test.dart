// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var dt = new DateTime.now();
  Expect.isTrue(dt is Comparable);

  var dt2 = new DateTime.fromMillisecondsSinceEpoch(100);
  var dt3 = new DateTime.fromMillisecondsSinceEpoch(200, isUtc: true);
  var dt3b = new DateTime.fromMillisecondsSinceEpoch(200);
  var dt4 = new DateTime.fromMillisecondsSinceEpoch(300);
  var dt5 = new DateTime.fromMillisecondsSinceEpoch(400, isUtc: true);
  var dt5b = new DateTime.fromMillisecondsSinceEpoch(400);

  Expect.isTrue(dt2.compareTo(dt2) == 0);
  Expect.isTrue(dt3.compareTo(dt3) == 0);
  Expect.isTrue(dt3b.compareTo(dt3b) == 0);
  Expect.isTrue(dt4.compareTo(dt4) == 0);
  Expect.isTrue(dt5.compareTo(dt5) == 0);
  Expect.isTrue(dt5b.compareTo(dt5b) == 0);

  // Time zones don't have any effect.
  Expect.isTrue(dt3.compareTo(dt3b) == 0);
  Expect.isTrue(dt5.compareTo(dt5b) == 0);

  Expect.isTrue(dt2.compareTo(dt3) < 0);
  Expect.isTrue(dt3.compareTo(dt4) < 0);
  Expect.isTrue(dt4.compareTo(dt5) < 0);

  Expect.isTrue(dt2.compareTo(dt3b) < 0);
  Expect.isTrue(dt4.compareTo(dt5b) < 0);

  Expect.isTrue(dt3.compareTo(dt2) > 0);
  Expect.isTrue(dt4.compareTo(dt3) > 0);
  Expect.isTrue(dt5.compareTo(dt4) > 0);

  Expect.isTrue(dt3b.compareTo(dt2) > 0);
  Expect.isTrue(dt5b.compareTo(dt4) > 0);
}
