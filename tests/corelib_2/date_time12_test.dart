// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

// Test DateTime.epoch

main() {
  const epoch = DateTime.epoch;

  var d1 = new DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  var d2 = new DateTime.fromMicrosecondsSinceEpoch(0, isUtc: true);

  Expect.equals(true, epoch == d1);
  Expect.equals(true, epoch == d2);
}
