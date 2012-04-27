// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

class RegExpTest {
  static test1() {
    RegExp exp = const RegExp("(\\w+)");
    String str = "Parse my string";
    List<Match> matches = new List<Match>.from(exp.allMatches(str));
    Expect.equals(3, matches.length);
    Expect.equals("Parse", matches[0].group(0));
    Expect.equals("my", matches[1].group(0));
    Expect.equals("string", matches[2].group(0));
  }

  static testMain() {
    test1();
  }
}

main() {
  RegExpTest.testMain();
}
