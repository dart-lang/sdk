// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("ExceptionImplementationTest.dart");
#import("dart:coreimpl");

main() {
  final msg = 1;
  try {
    throw new Exception(msg);
    Expect.fail("Unreachable");
  } catch (Exception e) {
    Expect.isTrue(e is Exception);
    Expect.isTrue(e is ExceptionImplementation);
    Expect.equals("Exception: $msg", e.toString());
  }
}
