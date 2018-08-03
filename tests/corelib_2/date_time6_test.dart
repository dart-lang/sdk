// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test DateTime comparison operators.

main() {
  var d = new DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  var d2 = new DateTime.fromMillisecondsSinceEpoch(1, isUtc: true);
  Expect.isTrue(d.isBefore(d2));
  Expect.isTrue(!d.isAfter(d2));
  Expect.isTrue(d2.isAfter(d));
  Expect.isTrue(!d2.isBefore(d));
  Expect.isFalse(d2.isBefore(d));
  Expect.isFalse(!d2.isAfter(d));
  Expect.isFalse(d.isAfter(d2));
  Expect.isFalse(!d.isBefore(d2));

  d = new DateTime.fromMillisecondsSinceEpoch(-1, isUtc: true);
  d2 = new DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  Expect.isTrue(d.isBefore(d2));
  Expect.isTrue(!d.isAfter(d2));
  Expect.isTrue(d2.isAfter(d));
  Expect.isTrue(!d2.isBefore(d));
  Expect.isFalse(d2.isBefore(d));
  Expect.isFalse(!d2.isAfter(d));
  Expect.isFalse(d.isAfter(d2));
  Expect.isFalse(!d.isBefore(d2));
}
