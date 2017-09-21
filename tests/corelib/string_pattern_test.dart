// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing String.allMatches.

import "package:expect/expect.dart";

String str = "this is a string with hello here and hello there";

main() {
  testNoMatch();
  testOneMatch();
  testTwoMatches();
  testEmptyPattern();
  testEmptyString();
  testEmptyPatternAndString();
  testMatchAsPrefix();
  testAllMatchesStart();
}

testNoMatch() {
  // Also tests that RegExp groups don't work.
  String helloPattern = "with (hello)";
  Iterable<Match> matches = helloPattern.allMatches(str);
  Expect.isFalse(matches.iterator.moveNext());
}

testOneMatch() {
  String helloPattern = "with hello";
  Iterable<Match> matches = helloPattern.allMatches(str);
  var iterator = matches.iterator;
  Expect.isTrue(iterator.moveNext());
  Match match = iterator.current;
  Expect.isFalse(iterator.moveNext());
  Expect.equals(str.indexOf('with', 0), match.start);
  Expect.equals(str.indexOf('with', 0) + helloPattern.length, match.end);
  Expect.equals(helloPattern, match.pattern);
  Expect.equals(str, match.input);
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
    Expect.equals(str.indexOf('hello', start) + helloPattern.length, match.end);
    Expect.equals(helloPattern, match.pattern);
    Expect.equals(str, match.input);
    Expect.equals(helloPattern, match[0]);
    Expect.equals(0, match.groupCount);
    start = match.end;
  }
  Expect.equals(2, count);
}

testEmptyPattern() {
  String pattern = "";
  Iterable<Match> matches = pattern.allMatches(str);
  Expect.isTrue(matches.iterator.moveNext());
}

testEmptyString() {
  String pattern = "foo";
  String str = "";
  Iterable<Match> matches = pattern.allMatches(str);
  Expect.isFalse(matches.iterator.moveNext());
}

testEmptyPatternAndString() {
  String pattern = "";
  String str = "";
  Iterable<Match> matches = pattern.allMatches(str);
  Expect.isTrue(matches.iterator.moveNext());
}

testMatchAsPrefix() {
  String pattern = "an";
  String str = "banana";
  Expect.isNull(pattern.matchAsPrefix(str));
  Expect.isNull(pattern.matchAsPrefix(str, 0));
  var m = pattern.matchAsPrefix(str, 1);
  Expect.equals("an", m[0]);
  Expect.equals(1, m.start);
  Expect.isNull(pattern.matchAsPrefix(str, 2));
  m = pattern.matchAsPrefix(str, 3);
  Expect.equals("an", m[0]);
  Expect.equals(3, m.start);
  Expect.isNull(pattern.matchAsPrefix(str, 4));
  Expect.isNull(pattern.matchAsPrefix(str, 5));
  Expect.isNull(pattern.matchAsPrefix(str, 6));
  Expect.throws(() => pattern.matchAsPrefix(str, -1));
  Expect.throws(() => pattern.matchAsPrefix(str, 7));
}

testAllMatchesStart() {
  String p = "ass";
  String s = "assassin";
  Expect.equals(2, p.allMatches(s).length);
  Expect.equals(2, p.allMatches(s, 0).length);
  Expect.equals(1, p.allMatches(s, 1).length);
  Expect.equals(0, p.allMatches(s, 4).length);
  Expect.equals(0, p.allMatches(s, s.length).length);
  Expect.throws(() => p.allMatches(s, -1));
  Expect.throws(() => p.allMatches(s, s.length + 1));
}
