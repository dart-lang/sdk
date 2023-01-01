// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

// Test DateTime comparison operators.

main() {
  var unixEpoch = new DateTime.unixEpoch();

  var d1 = new DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  var d2 = new DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  Expect.equals(unixEpoch.millisecondsSinceEpoch, d1.millisecondsSinceEpoch);
  Expect.equals(unixEpoch.millisecondsSinceEpoch, d2.millisecondsSinceEpoch);
}
