// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";

const String exceptionString = "exceptionalString";

throwString() async {
  try {
    throw exceptionString;
  } catch (e) {
    await 1;
    throw e;
  }
}

rethrowString() async {
  try {
    throw exceptionString;
  } catch (e) {
    await 1;
    rethrow;
  }
}

testThrow() {
  Future f = throwString();
  f.then((v) {
    Expect.fail("Exception not thrown");
  }, onError: (e) {
    Expect.equals(exceptionString, e);
  });
}

testRethrow() {
  Future f = rethrowString();
  f.then((v) {
    Expect.fail("Exception not thrown");
  }, onError: (e) {
    Expect.equals(exceptionString, e);
  });
}

main() {
  testThrow();
  testRethrow();
}
