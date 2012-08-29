// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

main() {
  String str = "";
  try {
    RegExp ex = new RegExp(str);
  } on Exception catch (e) {
    if (!(e is NullPointerException)) {
      Expect.fail("Expected: NullPointerException got: ${e}");
    }
  }
  Expect.isFalse(new RegExp(@"^\w+$").hasMatch(str));
  Match fm = new RegExp(@"^\w+$").firstMatch(str);
  Expect.equals(null, fm);

  Iterable<Match> am = new RegExp(@"^\w+$").allMatches(str);
  Expect.isFalse(am.iterator().hasNext());

  Expect.equals(null, new RegExp(@"^\w+$").stringMatch(str));
}
