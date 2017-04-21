// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to ensure that the VM does not have an integer overflow issue
// when concatenating strings.

import "package:expect/expect.dart";

main() {
  String a = "a";
  for (; a.length < 256 * 1024 * 1024;) a = a + a;

  var exception_thrown = false;
  try {
    var concat = "$a$a$a$a$a$a$a$a";
  } on OutOfMemoryError catch (exc) {
    exception_thrown = true;
  }
  Expect.isTrue(exception_thrown);
}
