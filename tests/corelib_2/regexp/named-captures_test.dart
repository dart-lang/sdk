// Copyright (c) 2019, the Dart project authors. All rights reserved.
// Copyright 2017 the V8 project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import 'package:expect/expect.dart';

import 'v8_regexp_utils.dart';

void main() {
  void execRE(RegExp re, String input, List<String> expectedResult) {
    assertTrue(re.hasMatch(input));
    shouldBe(re.firstMatch(input), expectedResult);
  }

  void execString(String pattern, String input, List<String> expectedResult,
      {bool unicode = true, bool caseSensitive: false}) {
    execRE(RegExp(pattern, unicode: unicode, caseSensitive: caseSensitive),
        input, expectedResult);
  }

  void namedRE(RegExp re, String input, Map<String, String> expectedResults) {
    assertTrue(re.hasMatch(input));
    var match = re.firstMatch(input);
    for (var s in expectedResults.keys) {
      assertEquals(match.namedGroup(s), expectedResults[s]);
    }
  }

  void execStringGroups(
      String pattern, String input, Map<String, String> expectedResults,
      {bool unicode = true, bool caseSensitive: false}) {
    namedRE(RegExp(pattern, unicode: unicode, caseSensitive: caseSensitive),
        input, expectedResults);
  }

  void hasNames(RegExp re, String input, List<String> expectedResults) {
    assertTrue(re.hasMatch(input));
    var match = re.firstMatch(input);
    for (var s in match.groupNames) {
      assertTrue(expectedResults.contains(s));
    }
  }

  void matchesIndexEqual(String input, RegExp re1, RegExp re2) {
    var m1 = re1.firstMatch(input);
    var m2 = re2.firstMatch(input);
    if (m2 == null) {
      assertNull(m1);
    } else {
      assertTrue(m1 != null);
      assertEquals(m1.groupCount, m2.groupCount);
      for (int i = 0; i < m1.groupCount; i++) {
        assertEquals(m1.group(i), m2.group(i));
      }
    }
  }

  // Malformed named captures.
  // Empty name.
  assertThrows(() => RegExp(r"(?<>a)", unicode: true));
  // Unterminated name.
  assertThrows(() => RegExp(r"(?<aa)", unicode: true));
  // Name starting with digits.
  assertThrows(() => RegExp(r"(?<42a>a)", unicode: true));
  // Name starting with invalid char.
  assertThrows(() => RegExp(r"(?<:a>a)", unicode: true));
  // Name containing invalid char.
  assertThrows(() => RegExp(r"(?<a:>a)", unicode: true));
  // Duplicate name.
  assertThrows(() => RegExp(r"(?<a>a)(?<a>a)", unicode: true));
  // Duplicate name.
  assertThrows(() => RegExp(r"(?<a>a)(?<b>b)(?<a>a)", unicode: true));
  // Invalid reference.
  assertThrows(() => RegExp(r"\k<a>", unicode: true));
  // Unterminated reference.
  assertThrows(() => RegExp(r"\k<a", unicode: true));
  // Lone \k.
  assertThrows(() => RegExp(r"\k", unicode: true));
  // Lone \k.
  assertThrows(() => RegExp(r"(?<a>.)\k", unicode: true));
  // Unterminated reference.
  assertThrows(() => RegExp(r"(?<a>.)\k<a", unicode: true));
  // Invalid reference.
  assertThrows(() => RegExp(r"(?<a>.)\k<b>", unicode: true));
  // Invalid reference.
  assertThrows(() => RegExp(r"(?<a>a)\k<ab>", unicode: true));
  // Invalid reference.
  assertThrows(() => RegExp(r"(?<ab>a)\k<a>", unicode: true));
  // Invalid reference.
  assertThrows(() => RegExp(r"\k<a>(?<ab>a)", unicode: true));
  // Identity escape in capture.
  assertThrows(() => RegExp(r"(?<a>\a)", unicode: true));

  // Behavior in non-unicode mode.
  assertThrows(() => RegExp(r"(?<>a)"));
  assertThrows(() => RegExp(r"(?<aa)"));
  assertThrows(() => RegExp(r"(?<42a>a)"));
  assertThrows(() => RegExp(r"(?<:a>a)"));
  assertThrows(() => RegExp(r"(?<a:>a)"));
  assertThrows(() => RegExp(r"(?<a>a)(?<a>a)"));
  assertThrows(() => RegExp(r"(?<a>a)(?<b>b)(?<a>a)"));
  assertTrue(RegExp(r"\k<a>").hasMatch("k<a>"));
  assertTrue(RegExp(r"\k<4>").hasMatch("k<4>"));
  assertTrue(RegExp(r"\k<a").hasMatch("k<a"));
  assertTrue(RegExp(r"\k").hasMatch("k"));
  assertThrows(() => RegExp(r"(?<a>.)\k"));
  assertThrows(() => RegExp(r"(?<a>.)\k<a"));
  assertThrows(() => RegExp(r"(?<a>.)\k<b>"));
  assertThrows(() => RegExp(r"(?<a>a)\k<ab>"));
  assertThrows(() => RegExp(r"(?<ab>a)\k<a>"));
  assertThrows(() => RegExp(r"\k<a>(?<ab>a)"));
  assertThrows(() => RegExp(r"\k<a(?<a>a)"));
  assertTrue(RegExp(r"(?<a>\a)").hasMatch("a"));

  var re = RegExp(r"\k<a>");
  execRE(re, "xxxk<a>xxx", ["k<a>"]);

  re = RegExp(r"\k<a");
  execRE(re, "xxxk<a>xxx", ["k<a"]);

  re = RegExp(r"(?<a>.)(?<b>.)(?<c>.)\k<c>\k<b>\k<a>");
  execRE(re, "abccba", ["abccba", "a", "b", "c"]);
  namedRE(re, "abccba", {"a": "a", "b": "b", "c": "c"});
  hasNames(re, "abccba", ["a", "b", "c"]);

  // A couple of corner cases around '\k' as named back-references vs. identity
  // escapes.
  assertTrue(RegExp(r"\k<a>(?<=>)a").hasMatch("k<a>a"));
  assertTrue(RegExp(r"\k<a>(?<!a)a").hasMatch("k<a>a"));
  assertTrue(RegExp(r"\k<a>(<a>x)").hasMatch("k<a><a>x"));
  assertTrue(RegExp(r"\k<a>(?<a>x)").hasMatch("x"));
  assertThrows(() => RegExp(r"\k<a>(?<b>x)"));
  assertThrows(() => RegExp(r"\k<a(?<a>.)"));
  assertThrows(() => RegExp(r"\k(?<a>.)"));

  // Basic named groups.
  execString(r"(?<a>a)", "bab", ["a", "a"]);
  execString(r"(?<a42>a)", "bab", ["a", "a"]);
  execString(r"(?<_>a)", "bab", ["a", "a"]);
  execString(r"(?<$>a)", "bab", ["a", "a"]);
  execString(r".(?<$>a).", "bab", ["bab", "a"]);
  execString(r".(?<a>a)(.)", "bab", ["bab", "a", "b"]);
  execString(r".(?<a>a)(?<b>.)", "bab", ["bab", "a", "b"]);
  execString(r".(?<a>\w\w)", "bab", ["bab", "ab"]);
  execString(r"(?<a>\w\w\w)", "bab", ["bab", "bab"]);
  execString(r"(?<a>\w\w)(?<b>\w)", "bab", ["bab", "ba", "b"]);

  execString(r"(?<a>a)", "bab", ["a", "a"], unicode: false);
  execString(r"(?<a42>a)", "bab", ["a", "a"], unicode: false);
  execString(r"(?<_>a)", "bab", ["a", "a"], unicode: false);
  execString(r"(?<$>a)", "bab", ["a", "a"], unicode: false);
  execString(r".(?<$>a).", "bab", ["bab", "a"], unicode: false);
  execString(r".(?<a>a)(.)", "bab", ["bab", "a", "b"], unicode: false);
  execString(r".(?<a>a)(?<b>.)", "bab", ["bab", "a", "b"], unicode: false);
  execString(r".(?<a>\w\w)", "bab", ["bab", "ab"], unicode: false);
  execString(r"(?<a>\w\w\w)", "bab", ["bab", "bab"], unicode: false);
  execString(r"(?<a>\w\w)(?<b>\w)", "bab", ["bab", "ba", "b"], unicode: false);

  matchesIndexEqual(
      "bab", RegExp(r"(?<a>a)", unicode: true), RegExp(r"(a)", unicode: true));
  matchesIndexEqual("bab", RegExp(r"(?<a42>a)", unicode: true),
      RegExp(r"(a)", unicode: true));
  matchesIndexEqual(
      "bab", RegExp(r"(?<_>a)", unicode: true), RegExp(r"(a)", unicode: true));
  matchesIndexEqual(
      "bab", RegExp(r"(?<$>a)", unicode: true), RegExp(r"(a)", unicode: true));
  matchesIndexEqual("bab", RegExp(r".(?<$>a).", unicode: true),
      RegExp(r".(a).", unicode: true));
  matchesIndexEqual("bab", RegExp(r".(?<a>a)(.)", unicode: true),
      RegExp(r".(a)(.)", unicode: true));
  matchesIndexEqual("bab", RegExp(r".(?<a>a)(?<b>.)", unicode: true),
      RegExp(r".(a)(.)", unicode: true));
  matchesIndexEqual("bab", RegExp(r".(?<a>\w\w)", unicode: true),
      RegExp(r".(\w\w)", unicode: true));
  matchesIndexEqual("bab", RegExp(r"(?<a>\w\w\w)", unicode: true),
      RegExp(r"(\w\w\w)", unicode: true));
  matchesIndexEqual("bab", RegExp(r"(?<a>\w\w)(?<b>\w)", unicode: true),
      RegExp(r"(\w\w)(\w)", unicode: true));

  execString(r"(?<b>b).\1", "bab", ["bab", "b"]);
  execString(r"(.)(?<a>a)\1\2", "baba", ["baba", "b", "a"]);
  execString(r"(.)(?<a>a)(?<b>\1)(\2)", "baba", ["baba", "b", "a", "b", "a"]);
  execString(r"(?<lt><)a", "<a", ["<a", "<"]);
  execString(r"(?<gt>>)a", ">a", [">a", ">"]);

  // Named references.
  var pattern = r"(?<b>.).\k<b>";
  execString(pattern, "bab", ["bab", "b"]);
  assertFalse(RegExp(pattern, unicode: true).hasMatch("baa"));

  // Nested groups.
  pattern = r"(?<a>.(?<b>.(?<c>.)))";
  execString(pattern, "bab", ["bab", "bab", "ab", "b"]);
  execStringGroups(pattern, "bab", {"a": "bab", "b": "ab", "c": "b"});

  // Reference inside group.
  pattern = r"(?<a>\k<a>\w)..";
  execString(pattern, "bab", ["bab", "b"]);
  execStringGroups(pattern, "bab", {"a": "b"});

  // Reference before group.
  pattern = r"\k<a>(?<a>b)\w\k<a>";
  execString(pattern, "bab", ["bab", "b"], unicode: false);
  execString(pattern, "bab", ["bab", "b"]);
  execStringGroups(pattern, "bab", {"a": "b"});

  pattern = r"(?<b>b)\k<a>(?<a>a)\k<b>";
  execString(pattern, "bab", ["bab", "b", "a"], unicode: false);
  execString(pattern, "bab", ["bab", "b", "a"]);
  execStringGroups(pattern, "bab", {"a": "a", "b": "b"});

  // Reference named groups.
  var match = RegExp(r"(?<a>a)(?<b>b)\k<a>", unicode: true).firstMatch("aba");
  assertEquals("a", match.namedGroup("a"));
  assertEquals("b", match.namedGroup("b"));
  assertFalse(match.groupNames.contains("c"));

  match =
      RegExp(r"(?<a>a)(?<b>b)\k<a>|(?<c>c)", unicode: true).firstMatch("aba");
  assertNull(match.namedGroup("c"));

  // Unicode names.
  execStringGroups(r"(?<π>a)", "bab", {"π": "a"});
  execStringGroups(r"(?<\u{03C0}>a)", "bab", {"π": "a"});
  execStringGroups(r"(?<π>a)", "bab", {"\u03C0": "a"});
  execStringGroups(r"(?<\u{03C0}>a)", "bab", {"\u03C0": "a"});
  execStringGroups(r"(?<$>a)", "bab", {"\$": "a"});
  execStringGroups(r"(?<_>a)", "bab", {"_": "a"});
  execStringGroups(r"(?<$𐒤>a)", "bab", {"\$𐒤": "a"});
  execStringGroups(r"(?<_\u200C>a)", "bab", {"_\u200C": "a"});
  execStringGroups(r"(?<_\u200D>a)", "bab", {"_\u200D": "a"});
  execStringGroups(r"(?<ಠ_ಠ>a)", "bab", {"ಠ_ಠ": "a"});
  // ID_Continue but not ID_Start.
  assertThrows(() => RegExp(r"/(?<❤>a)", unicode: true));
  assertThrows(() => RegExp(r"/(?<𐒤>a)", unicode: true));

  execStringGroups(r"(?<π>a)", "bab", {"π": "a"}, unicode: false);
  execStringGroups(r"(?<$>a)", "bab", {"\$": "a"}, unicode: false);
  execStringGroups(r"(?<_>a)", "bab", {"_": "a"}, unicode: false);
  assertThrows(() => RegExp(r"(?<$𐒤>a)"));
  execStringGroups(r"(?<ಠ_ಠ>a)", "bab", {"ಠ_ಠ": "a"}, unicode: false);
  // ID_Continue but not ID_Start.
  assertThrows(() => RegExp(r"/(?<❤>a)"));
  assertThrows(() => RegExp(r"/(?<𐒤>a)"));

  // Interaction with lookbehind assertions.
  pattern = r"(?<=(?<a>\w){3})f";
  execString(pattern, "abcdef", ["f", "c"]);
  execStringGroups(pattern, "abcdef", {"a": "c"});

  execStringGroups(r"(?<=(?<a>\w){4})f", "abcdef", {"a": "b"});
  execStringGroups(r"(?<=(?<a>\w)+)f", "abcdef", {"a": "a"});
  assertFalse(RegExp(r"(?<=(?<a>\w){6})f", unicode: true).hasMatch("abcdef"));

  execString(r"((?<=\w{3}))f", "abcdef", ["f", ""]);
  execString(r"(?<a>(?<=\w{3}))f", "abcdef", ["f", ""]);

  execString(r"(?<!(?<a>\d){3})f", "abcdef", ["f", null]);
  assertFalse(RegExp(r"(?<!(?<a>\D){3})f", unicode: true).hasMatch("abcdef"));

  execString(r"(?<!(?<a>\D){3})f|f", "abcdef", ["f", null]);
  execString(r"(?<a>(?<!\D{3}))f|f", "abcdef", ["f", null]);

  // Matches contain the names of named captures
  match = RegExp(r"(?<fst>.)|(?<snd>.)", unicode: true).firstMatch("abcd");
  Expect.setEquals(["fst", "snd"], match.groupNames);

  // Backslash as ID_Start and ID_Continue (v8:5868).
  assertThrows(() => RegExp("(?<\\>.)")); // '\' misclassified as ID_Start.
  assertThrows(() => RegExp("(?<a\\>.)")); // '\' misclassified as ID_Continue.

  // Backreference before the group (exercises the capture mini-parser).
  assertThrows(() => RegExp(r"/\1(?:.)", unicode: true));
  assertThrows(() => RegExp(r"/\1(?<=a).", unicode: true));
  assertThrows(() => RegExp(r"/\1(?<!a).", unicode: true));
  execString(r"\1(?<a>.)", "abcd", ["a", "a"]);

  // Unicode escapes in capture names. (Testing both unicode interpreted by
  // Dart string handling and also escaped unicode making it to RegExp parser.)

  // \u Lead \u Trail
  assertTrue(RegExp("(?<a\uD801\uDCA4>.)", unicode: true).hasMatch("a"));
  assertTrue(RegExp(r"(?<a\uD801\uDCA4>.)", unicode: true).hasMatch("a"));
  assertThrows(() => RegExp("(?<a\uD801>.)", unicode: true)); // \u Lead
  assertThrows(() => RegExp(r"(?<a\uD801>.)", unicode: true)); // \u Lead
  assertThrows(() => RegExp("(?<a\uDCA4>.)", unicode: true)); // \u Trail
  assertThrows(() => RegExp(r"(?<a\uDCA4>.)", unicode: true)); // \u Trail
  // \u NonSurrogate
  assertTrue(RegExp("(?<\u0041>.)", unicode: true).hasMatch("a"));
  assertTrue(RegExp(r"(?<\u0041>.)", unicode: true).hasMatch("a"));
  // \u{ Surrogate, ID_Continue }
  assertTrue(RegExp("(?<a\u{104A4}>.)", unicode: true).hasMatch("a"));
  assertTrue(RegExp(r"(?<a\u{104A4}>.)", unicode: true).hasMatch("a"));

  // \u{ Out-of-bounds } -- only need to test RegExp parser for this.
  assertThrows(() => RegExp(r"(?<a\\u{110000}>.)", unicode: true));

  // Also checking non-unicode patterns, where surrogate pairs will not
  // be combined (so only \u0041 will have any success).

  assertThrows(() => RegExp("(?<a\uD801\uDCA4>.)"));
  assertThrows(() => RegExp(r"(?<a\uD801\uDCA4>.)"));
  assertThrows(() => RegExp("(?<a\uD801>.)"));
  assertThrows(() => RegExp(r"(?<a\uD801>.)"));
  assertThrows(() => RegExp("(?<a\uDCA4>.)"));
  assertThrows(() => RegExp(r"(?<a\uDCA4>.)"));
  assertTrue(RegExp("(?<\u0041>.)").hasMatch("a"));
  assertTrue(RegExp(r"(?<\u0041>.)").hasMatch("a"));
  assertThrows(() => RegExp("(?<a\u{104A4}>.)"));
  assertThrows(() => RegExp(r"(?<a\u{104A4}>.)"));
  assertThrows(() => RegExp("(?<a\u{10FFFF}>.)"));
  assertThrows(() => RegExp(r"(?<a\u{10FFFF}>.)"));
  assertThrows(() => RegExp(r"(?<a\\u{110000}>.)"));
}
