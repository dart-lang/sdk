// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

import "package:expect/expect.dart";

main() {
  String str = "";
  try {
    RegExp ex = new RegExp(str);
  } catch (e) {
    if (!(e is ArgumentError)) {
      Expect.fail("Expected: ArgumentError got: ${e}");
    }
  }
  Expect.isFalse(new RegExp(r"^\w+$").hasMatch(str));
  Match fm = new RegExp(r"^\w+$").firstMatch(str);
  Expect.equals(null, fm);

  Iterable<Match> am = new RegExp(r"^\w+$").allMatches(str);
  Expect.isFalse(am.iterator.moveNext());

  Expect.equals(null, new RegExp(r"^\w+$").stringMatch(str));
}
