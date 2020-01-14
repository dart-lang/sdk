// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that the runtime still runs the code after a try/catch. The
// test cannot use Expect.throws, because Expect.throws uses the same
// pattern.

import "package:expect/expect.dart";

main() {
  var exception;
  try {
    throw 'foo';
  } on String catch (ex) {
    exception = ex;
  }
  Expect.isTrue(exception is String);
  throw 'foo'; //# 01: runtime error
}
