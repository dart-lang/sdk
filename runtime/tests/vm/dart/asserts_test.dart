// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable-asserts
// Dart test program testing assert statements.

import "package:expect/expect.dart";

main(List<String> args) {
  Expect.throws(() {
    assert(/* this */ args.length == -1 && /* that */ args.length == 0);
  }, (e) {
    if (e is! AssertionError) {
      return false;
    }
    print('Exception: $e');
    return e.toString().contains(
        "asserts_test.dart': Failed assertion: line 11 pos 23: 'args.length == -1 && /* that */ args.length == 0':");
  });
}
