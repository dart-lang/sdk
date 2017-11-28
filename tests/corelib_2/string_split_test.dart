// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  testSplitString();
  testSplitRegExp();
  testSplitPattern();
}

testSplit(List<String> expect, String string, Pattern pattern) {
  String patternString;
  if (pattern is String) {
    patternString = '"$pattern"';
  } else if (pattern is RegExp) {
    patternString = "/${pattern.pattern}/";
  } else {
    patternString = pattern.toString();
  }
  List actual = string.split(pattern);

  // Check that the list is growable/mutable
  actual
    ..add('42')
    ..removeLast();

  // Ensure that the correct type is reified.
  actual = actual as List<String>;
  Expect.throwsTypeError(() => actual.add(42),
      'List<String>.add should not accept an int');

  Expect.listEquals(expect, actual, '"$string".split($patternString)');
}

/** String patterns. */
void testSplitString() {
  // Normal match.
  testSplit(["a", "b", "c"], "a b c", " ");
  testSplit(["a", "b", "c"], "adbdc", "d");
  testSplit(["a", "b", "c"], "addbddc", "dd");
  // No match.
  testSplit(["abc"], "abc", " ");
  testSplit(["a"], "a", "b");
  testSplit([""], "", "b");
  // Empty match matches everywhere except start/end.
  testSplit(["a", "b", "c"], "abc", "");
  // All empty parts.
  testSplit(["", "", "", "", ""], "aaaa", "a");
  testSplit(["", "", "", "", ""], "    ", " ");
  testSplit(["", ""], "a", "a");
  // No overlapping matches. Match as early as possible.
  testSplit(["", "", "", "a"], "aaaaaaa", "aa");
  // Cannot split the empty string.
  testSplit([], "", ""); // Match.
  testSplit([""], "", "a"); // No match.
}

/** RegExp patterns. */
void testSplitRegExp() {
  testSplitWithRegExp((s) => new RegExp(s));
}

/** Non-String, non-RegExp patterns. */
void testSplitPattern() {
  testSplitWithRegExp((s) => new RegExpWrap(s));
}

void testSplitWithRegExp(makePattern) {
  testSplit(["a", "b", "c"], "a b c", makePattern(r" "));

  testSplit(["a", "b", "c"], "adbdc", makePattern(r"[dz]"));

  testSplit(["a", "b", "c"], "addbddc", makePattern(r"dd"));

  testSplit(["abc"], "abc", makePattern(r"b$"));

  testSplit(["a", "b", "c"], "abc", makePattern(r""));

  testSplit(["", "", "", ""], "   ", makePattern(r"[ ]"));

  // Non-zero-length match at end.
  testSplit(["aa", ""], "aaa", makePattern(r"a$"));

  // Zero-length match at end.
  testSplit(["aaa"], "aaa", makePattern(r"$"));

  // Non-zero-length match at start.
  testSplit(["", "aa"], "aaa", makePattern(r"^a"));

  // Zero-length match at start.
  testSplit(["aaa"], "aaa", makePattern(r"^"));

  // Picks first match, not longest or shortest.
  testSplit(["", "", "", "a"], "aaaaaaa", makePattern(r"aa|aaa"));

  testSplit(["", "", "", "a"], "aaaaaaa", makePattern(r"aa|"));

  testSplit(["", "", "a"], "aaaaaaa", makePattern(r"aaa|aa"));

  // Zero-width match depending on the following.
  testSplit(["a", "bc"], "abc", makePattern(r"(?=[ab])"));

  testSplit(["a", "b", "c"], "abc", makePattern(r"(?!^)"));

  // Cannot split empty string.
  testSplit([], "", makePattern(r""));

  testSplit([], "", makePattern(r"(?:)"));

  testSplit([], "", makePattern(r"$|(?=.)"));

  testSplit([""], "", makePattern(r"a"));

  // Can split singleton string if it matches.
  testSplit(["", ""], "a", makePattern(r"a"));

  testSplit(["a"], "a", makePattern(r"b"));

  // Do not include captures.
  testSplit(["a", "", "a"], "abba", makePattern(r"(b)"));

  testSplit(["a", "a"], "abba", makePattern(r"(bb)"));

  testSplit(["a", "a"], "abba", makePattern(r"(b*)"));

  testSplit(["a", "a"], "aa", makePattern(r"(b*)"));

  // But captures are still there, and do work with backreferences.
  testSplit(["a", "cba"], "abcba", makePattern(r"([bc])(?=.*\1)"));
}

// A Pattern implementation with the same capabilities as a RegExp, but not
// directly recognizable as a RegExp.
class RegExpWrap implements Pattern {
  final regexp;
  RegExpWrap(String source) : regexp = new RegExp(source);
  Iterable<Match> allMatches(String string, [int start = 0]) =>
      regexp.allMatches(string, start);

  Match matchAsPrefix(String string, [int start = 0]) =>
      regexp.matchAsPrefix(string, start);

  String toString() => "Wrap(/${regexp.pattern}/)";
}
