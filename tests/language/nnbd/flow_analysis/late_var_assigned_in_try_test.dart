// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that when a late variable is assigned in a try block and
// read in a catch or finally block, that there is no compile-time error,
// because the assignment might happen prior to the exception occurring.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

void tryCatch() {
  late int x;
  try {
    x = 10;
    throw 'foo';
  } catch (_) {
    Expect.equals(x, 10);
  }
}

void tryFinally() {
  late int x;
  try {
    x = 10;
  } finally {
    Expect.equals(x, 10);
  }
}

main() {
  tryCatch();
  tryFinally();
}
