// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing regular expressions in Dart.

import "package:expect/expect.dart";

void main() {
  RegExp exp = new RegExp(r"(\w+)");
  String str = "Parse my string";
  List<Match> matches = exp.allMatches(str).toList();
  Expect.equals(3, matches.length);
  Expect.equals("Parse", matches[0].group(0));
  Expect.equals("my", matches[1].group(0));
  Expect.equals("string", matches[2].group(0));

  // Check that allMatches progresses correctly for empty matches, and that
  // it includes the empty match at the end position.
  exp = new RegExp("a?");
  str = "babba";
  Expect.listEquals(["", "a", "", "", "a", ""],
                    exp.allMatches(str).map((x)=>x[0]).toList());

  // Check that allMatches works with optional start index.
  exp = new RegExp("as{2}");
  str = "assassin";
  Expect.equals(2, exp.allMatches(str).length);
  Expect.equals(2, exp.allMatches(str, 0).length);
  Expect.equals(1, exp.allMatches(str, 1).length);
  Expect.equals(0, exp.allMatches(str, 4).length);
  Expect.equals(0, exp.allMatches(str, str.length).length);
  Expect.throws(() => exp.allMatches(str, -1));
  Expect.throws(() => exp.allMatches(str, str.length + 1));

  exp = new RegExp(".*");
  Expect.equals("", exp.allMatches(str, str.length).single[0]);

  // The "^" must only match at the beginning of the string.
  // Using a start-index doesn't change where the string starts.
  exp = new RegExp("^ass");
  Expect.equals(1, exp.allMatches(str, 0).length);
  Expect.equals(0, exp.allMatches(str, 3).length);

  // Regression test for http://dartbug.com/2980
  exp = new RegExp("^", multiLine: true);  // Any zero-length match will work.
  str = "foo\nbar\nbaz";
  Expect.equals(" foo\n bar\n baz", str.replaceAll(exp, " "));

  exp = new RegExp(r"(\w+)");
  Expect.isNull(exp.matchAsPrefix(" xyz ab"));
  Expect.isNull(exp.matchAsPrefix(" xyz ab", 0));

  var m = exp.matchAsPrefix(" xyz ab", 1);
  Expect.equals("xyz", m[0]);
  Expect.equals("xyz", m[1]);
  Expect.equals(1, m.groupCount);

  m = exp.matchAsPrefix(" xyz ab", 2);
  Expect.equals("yz", m[0]);
  Expect.equals("yz", m[1]);
  Expect.equals(1, m.groupCount);

  m = exp.matchAsPrefix(" xyz ab", 3);
  Expect.equals("z", m[0]);
  Expect.equals("z", m[1]);
  Expect.equals(1, m.groupCount);

  Expect.isNull(exp.matchAsPrefix(" xyz ab", 4));

  m = exp.matchAsPrefix(" xyz ab", 5);
  Expect.equals("ab", m[0]);
  Expect.equals("ab", m[1]);
  Expect.equals(1, m.groupCount);

  m = exp.matchAsPrefix(" xyz ab", 6);
  Expect.equals("b", m[0]);
  Expect.equals("b", m[1]);
  Expect.equals(1, m.groupCount);

  Expect.isNull(exp.matchAsPrefix(" xyz ab", 7));

  Expect.throws(() => exp.matchAsPrefix(" xyz ab", -1));
  Expect.throws(() => exp.matchAsPrefix(" xyz ab", 8));
}
