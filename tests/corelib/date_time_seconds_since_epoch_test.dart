// Copyright (c) 2012, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for DateTime.secondsSinceEpoch.

testSecondsSinceEpoch(DateTime original, int expectedSeconds) {
  final result = original.secondsSinceEpoch;
  Expect.equals(expectedSeconds, result);
}

void main() {
  final epoch = DateTime.utc(1970, 1, 1);
  final oneHourLater = DateTime.utc(1970, 1, 1, 1); // 3600 seconds since epoch

  testSecondsSinceEpoch(epoch, 0);
  testSecondsSinceEpoch(oneHourLater, 3600);
}
