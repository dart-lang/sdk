// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to ensure that the VM does not have an integer overflow issue
// when concatenating strings and hitting length 2^31.
// See https://github.com/dart-lang/sdk/issues/11214

import "package:expect/expect.dart";

main() {
  const length28bits = 1 << 28;
  String a = "a";
  while (a.length < length28bits) {
    a = a + a;
  }
  Expect.equals(a.length, length28bits);
  try {
    final concat = "$a$a$a$a$a$a$a$a";
    Expect.equals(concat.length, 8 * length28bits);
  } on OutOfMemoryError {
    // Allow test to run out of memory instead.
  }
}
