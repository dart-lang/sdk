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

  // Regression test for http://dartbug.com/2980
  exp = new RegExp("^", multiLine: true);  // Any zero-length match will work.
  str = "foo\nbar\nbaz";
  Expect.equals(" foo\n bar\n baz", str.replaceAll(exp, " "));
}
