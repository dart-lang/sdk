// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Test to ensure that the VM does not have an integer overflow issue
// when concatenating strings.
// See https://github.com/dart-lang/sdk/issues/11214

import "package:expect/expect.dart";

main() {
  String a = "a";

  var caughtOutOfMemoryException = false;
  try {
    while (true) {
      a = "$a$a$a$a$a$a$a$a";
    }
  } on OutOfMemoryError {
    caughtOutOfMemoryException = true;
  }
  Expect.isTrue(caughtOutOfMemoryException);
  Expect.isTrue(a.startsWith('aaaaa') && a.length > 1024);
}
