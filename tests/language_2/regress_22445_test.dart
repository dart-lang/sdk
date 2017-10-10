// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";

foo() async {
  try {
    print("a");
    await new Future.value(3);
    print("b");
    throw "Error";
    print("c");
  } catch (e) {
    print("d");
    await new Future.error("Error2");
  } finally {
    print("e");
  }
  print("f");
}

main() async {
  var error = "no error";
  try {
    await foo();
  } catch (e) {
    error = e;
  }
  Expect.equals("Error2", error);
}
