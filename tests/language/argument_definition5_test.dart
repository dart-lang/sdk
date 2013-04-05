// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var x = "";

test(String str, [onError(String)]) {
  return (() {
    try {
      throw "";
    } catch(e) {
      if (?onError) {
        onError(str);
      } else {
        x = "${str} error";
      }
    }
  });
}

ignoreError(String str) {
  x = "${str} error ignored";
}

main() {
  Expect.equals("", x);
  test("test")();
  Expect.equals("test error", x);
  test("test", ignoreError)();
  Expect.equals("test error ignored", x);
}
