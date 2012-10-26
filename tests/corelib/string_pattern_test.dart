// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing String.allMatches.

String str = "this is a string with hello here and hello there";

main() {
  testNoMatch();
  testOneMatch();
  testTwoMatches();
  testEmptyPattern();
  testEmptyString();
  testEmptyPatternAndString();
}

testNoMatch() {
  // Also tests that RegExp groups don't work.
  String helloPattern = "with (hello)";
  Iterable<Match> matches = helloPattern.allMatches(str);
  Expect.isFalse(matches.iterator().hasNext);
}

testOneMatch() {
  String helloPattern = "with hello";
  Iterable<Match> matches = helloPattern.allMatches(str);
  var iterator = matches.iterator();
  Match match = iterator.next();
  Expect.isFalse(iterator.hasNext);
  Expect.equals(str.indexOf('with', 0), match.start);
  Expect.equals(str.indexOf('with', 0) + helloPattern.length, match.end);
  Expect.equals(helloPattern, match.pattern);
  Expect.equals(str, match.str);
  Expect.equals(helloPattern, match[0]);
  Expect.equals(0, match.groupCount);
}

testTwoMatches() {
  String helloPattern = "hello";
  Iterable<Match> matches = helloPattern.allMatches(str);

  int count = 0;
  int start = 0;
  for (var match in matches) {
    count++;
    Expect.equals(str.indexOf('hello', start), match.start);
    Expect.equals(
        str.indexOf('hello', start) + helloPattern.length, match.end);
    Expect.equals(helloPattern, match.pattern);
    Expect.equals(str, match.str);
    Expect.equals(helloPattern, match[0]);
    Expect.equals(0, match.groupCount);
    start = match.end;
  }
  Expect.equals(2, count);
}

testEmptyPattern() {
  String pattern = "";
  Iterable<Match> matches = pattern.allMatches(str);
  Expect.isTrue(matches.iterator().hasNext);
}

testEmptyString() {
  String pattern = "foo";
  String str = "";
  Iterable<Match> matches = pattern.allMatches(str);
  Expect.isFalse(matches.iterator().hasNext);
}

testEmptyPatternAndString() {
  String pattern = "";
  String str = "";
  Iterable<Match> matches = pattern.allMatches(str);
  Expect.isTrue(matches.iterator().hasNext);
}
