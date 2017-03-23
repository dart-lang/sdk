// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";

foo() async {
  try {
    try {
      await for (var c in new Stream.fromIterable([])) {} // //# 01: ok
      await 0; // //# 02: ok
    } catch (error) {}
  } catch (error) {}
  throw "error";
}

main() async {
  var error = "no error";
  try {
    await foo();
  } catch (e) {
    error = e;
  }
  Expect.equals("error", error);
}
