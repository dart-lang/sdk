// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for crash in VM parser (issue 29370).

import "package:expect/expect.dart";

const ERROR_A = 0;
const ERROR_B = 1;

errorToString(error) {
  switch (error) {
    case ERROR_A:
      return "ERROR_A";
    case ERROR_B = 1: //# 01: compile-time error
    case ERROR_B: //# none: ok
      return "ERROR_B";
    default:
      return "Unknown error";
  }
}

main() {
  Expect.equals(errorToString(ERROR_A), "ERROR_A");
  Expect.equals(errorToString(ERROR_B), "ERROR_B");
  Expect.equals(errorToString(55), "Unknown error");
}
