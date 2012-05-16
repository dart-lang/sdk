// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test Date comparison operators.

main() {
  var d = new Date.fromEpoch(0, const TimeZone.utc());
  var d2 = new Date.fromEpoch(1, const TimeZone.utc());
  Expect.isTrue(d < d2);
  Expect.isTrue(d <= d2);
  Expect.isTrue(d2 > d);
  Expect.isTrue(d2 >= d);
  Expect.isFalse(d2 < d);
  Expect.isFalse(d2 <= d);
  Expect.isFalse(d > d2);
  Expect.isFalse(d >= d2);

  d = new Date.fromEpoch(-1, const TimeZone.utc());
  d2 = new Date.fromEpoch(0, const TimeZone.utc());
  Expect.isTrue(d < d2);
  Expect.isTrue(d <= d2);
  Expect.isTrue(d2 > d);
  Expect.isTrue(d2 >= d);
  Expect.isFalse(d2 < d);
  Expect.isFalse(d2 <= d);
  Expect.isFalse(d > d2);
  Expect.isFalse(d >= d2);
}
