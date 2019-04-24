// Copyright (c) 2019, the Dart project authors. All rights reserved.
// Copyright 2015 the V8 project authors. All rights reserved.
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
  // Tests captures in positive and negative look-behind in regular expressions.

  void testRE(RegExp re, String input, bool expectedResult) {
    if (expectedResult) {
      assertTrue(re.hasMatch(input));
    } else {
      assertFalse(re.hasMatch(input));
    }
  }

  void execRE(RegExp re, String input, List<String> expectedResult) {
    assertTrue(re.hasMatch(input));
    shouldBe(re.firstMatch(input), expectedResult);
  }

  void multiRE(RegExp re, String input, List<List<String>> expectedResult) {
    assertTrue(re.hasMatch(input));
    final matches = re.allMatches(input);
    assertEquals(matches.length, expectedResult.length);
    for (var i = 0; i < matches.length; i++) {
      shouldBe(matches.elementAt(i), expectedResult[i]);
    }
  }

  // Simple fixed-length matches.

  var re = new RegExp(r"^.(?<=a)");
  execRE(re, "a", ["a"]);
  testRE(re, "b", false);

  re = new RegExp(r"^f..(?<=.oo)");
  execRE(re, "foo1", ["foo"]);

  re = new RegExp(r"^f\w\w(?<=\woo)");
  execRE(re, "foo2", ["foo"]);
  testRE(re, "boo", false);
  testRE(re, "fao", false);
  testRE(re, "foa", false);

  re = new RegExp(r"(?<=abc)\w\w\w");
  execRE(re, "abcdef", ["def"]);

  re = new RegExp(r"(?<=a.c)\w\w\w");
  execRE(re, "abcdef", ["def"]);

  re = new RegExp(r"(?<=a\wc)\w\w\w");
  execRE(re, "abcdef", ["def"]);

  re = new RegExp(r"(?<=a[a-z])\w\w\w");
  execRE(re, "abcdef", ["cde"]);

  re = new RegExp(r"(?<=a[a-z][a-z])\w\w\w");
  execRE(re, "abcdef", ["def"]);

  re = new RegExp(r"(?<=a[a-z]{2})\w\w\w");
  execRE(re, "abcdef", ["def"]);

  re = new RegExp(r"(?<=a{1})\w\w\w");
  execRE(re, "abcdef", ["bcd"]);

  re = new RegExp(r"(?<=a{1}b{1})\w\w\w");
  execRE(re, "abcdef", ["cde"]);

  re = new RegExp(r"(?<=a{1}[a-z]{2})\w\w\w");
  execRE(re, "abcdef", ["def"]);

  // Variable-length matches.

  re = new RegExp(r"(?<=[a|b|c]*)[^a|b|c]{3}");
  execRE(re, "abcdef", ["def"]);

  re = new RegExp(r"(?<=\w*)[^a|b|c]{3}");
  execRE(re, "abcdef", ["def"]);

  re = new RegExp(r"(?<=b|c)\w");
  multiRE(re, "abcdef", [
    ["c"],
    ["d"]
  ]);

  re = new RegExp(r"(?<=[b-e])\w{2}");
  multiRE(re, "abcdef", [
    ["cd"],
    ["ef"]
  ]);

  // Start of line matches.

  re = new RegExp(r"(?<=^abc)def");
  execRE(re, "abcdef", ["def"]);

  re = new RegExp(r"(?<=^[a-c]{3})def");
  execRE(re, "abcdef", ["def"]);

  re = new RegExp(r"(?<=^[a-c]{3})def", multiLine: true);
  execRE(re, "xyz\nabcdef", ["def"]);

  re = new RegExp(r"(?<=^)\w+", multiLine: true);
  multiRE(re, "ab\ncd\nefg", [
    ["ab"],
    ["cd"],
    ["efg"]
  ]);

  re = new RegExp(r"\w+(?<=$)", multiLine: true);
  multiRE(re, "ab\ncd\nefg", [
    ["ab"],
    ["cd"],
    ["efg"]
  ]);

  re = new RegExp(r"(?<=^)\w+(?<=$)", multiLine: true);
  multiRE(re, "ab\ncd\nefg", [
    ["ab"],
    ["cd"],
    ["efg"]
  ]);

  re = new RegExp(r"(?<=^[^a-c]{3})def");
  testRE(re, "abcdef", false);

  re = new RegExp(r"^foooo(?<=^o+)$");
  testRE(re, "foooo", false);

  re = new RegExp(r"^foooo(?<=^o*)$");
  testRE(re, "foooo", false);

  re = new RegExp(r"^foo(?<=^fo+)$");
  execRE(re, "foo", ["foo"]);

  re = new RegExp(r"^foooo(?<=^fo*)");
  execRE(re, "foooo", ["foooo"]);

  re = new RegExp(r"^(f)oo(?<=^\1o+)$");
  testRE(re, "foo", true);
  execRE(re, "foo", ["foo", "f"]);

  re = new RegExp(r"^(f)oo(?<=^\1o+)$", caseSensitive: false);
  execRE(re, "foo", ["foo", "f"]);

  re = new RegExp(r"^(f)oo(?<=^\1o+).$", caseSensitive: false);
  execRE(re, "foo\u1234", ["foo\u1234", "f"]);

  re = new RegExp(r"(?<=^\w+)def");
  execRE(re, "abcdefdef", ["def"]);
  multiRE(re, "abcdefdef", [
    ["def"],
    ["def"]
  ]);

  // Word boundary matches.

  re = new RegExp(r"(?<=\b)[d-f]{3}");
  execRE(re, "abc def", ["def"]);

  re = new RegExp(r"(?<=\B)\w{3}");
  execRE(re, "ab cdef", ["def"]);

  re = new RegExp(r"(?<=\B)(?<=c(?<=\w))\w{3}");
  execRE(re, "ab cdef", ["def"]);

  re = new RegExp(r"(?<=\b)[d-f]{3}");
  testRE(re, "abcdef", false);

  // Negative lookbehind.

  re = new RegExp(r"(?<!abc)\w\w\w");
  execRE(re, "abcdef", ["abc"]);

  re = new RegExp(r"(?<!a.c)\w\w\w");
  execRE(re, "abcdef", ["abc"]);

  re = new RegExp(r"(?<!a\wc)\w\w\w");
  execRE(re, "abcdef", ["abc"]);

  re = new RegExp(r"(?<!a[a-z])\w\w\w");
  execRE(re, "abcdef", ["abc"]);

  re = new RegExp(r"(?<!a[a-z]{2})\w\w\w");
  execRE(re, "abcdef", ["abc"]);

  re = new RegExp(r"(?<!abc)def");
  testRE(re, "abcdef", false);

  re = new RegExp(r"(?<!a.c)def");
  testRE(re, "abcdef", false);

  re = new RegExp(r"(?<!a\wc)def");
  testRE(re, "abcdef", false);

  re = new RegExp(r"(?<!a[a-z][a-z])def");
  testRE(re, "abcdef", false);

  re = new RegExp(r"(?<!a[a-z]{2})def");
  testRE(re, "abcdef", false);

  re = new RegExp(r"(?<!a{1}b{1})cde");
  testRE(re, "abcdef", false);

  re = new RegExp(r"(?<!a{1}[a-z]{2})def");
  testRE(re, "abcdef", false);

  // Capturing matches.
  re = new RegExp(r"(?<=(c))def");
  execRE(re, "abcdef", ["def", "c"]);

  re = new RegExp(r"(?<=(\w{2}))def");
  execRE(re, "abcdef", ["def", "bc"]);

  re = new RegExp(r"(?<=(\w(\w)))def");
  execRE(re, "abcdef", ["def", "bc", "c"]);

  re = new RegExp(r"(?<=(\w){3})def");
  execRE(re, "abcdef", ["def", "a"]);

  re = new RegExp(r"(?<=(bc)|(cd)).");
  execRE(re, "abcdef", ["d", "bc", null]);

  re = new RegExp(r"(?<=([ab]{1,2})\D|(abc))\w");
  execRE(re, "abcdef", ["c", "a", null]);

  re = new RegExp(r"\D(?<=([ab]+))(\w)");
  execRE(re, "abcdef", ["ab", "a", "b"]);

  // Captures inside negative lookbehind. (They never capture.)
  re = new RegExp(r"(?<!(^|[ab]))\w{2}");
  execRE(re, "abcdef", ["de", null]);

  // Nested lookaround.
  re = new RegExp(r"(?<=ab(?=c)\wd)\w\w");
  execRE(re, "abcdef", ["ef"]);

  re = new RegExp(r"(?<=a(?=([^a]{2})d)\w{3})\w\w");
  execRE(re, "abcdef", ["ef", "bc"]);

  re = new RegExp(r"(?<=a(?=([bc]{2}(?<!a{2}))d)\w{3})\w\w");
  execRE(re, "abcdef", ["ef", "bc"]);

  re = new RegExp(r"(?<=a(?=([bc]{2}(?<!a*))d)\w{3})\w\w/");
  testRE(re, "abcdef", false);

  re = new RegExp(r"^faaao?(?<=^f[oa]+(?=o))");
  execRE(re, "faaao", ["faaa"]);

  // Back references.
  re = new RegExp(r"(.)(?<=(\1\1))");
  execRE(re, "abb", ["b", "b", "bb"]);

  re = new RegExp(r"(.)(?<=(\1\1))", caseSensitive: false);
  execRE(re, "abB", ["B", "B", "bB"]);

  re = new RegExp(r"((\w)\w)(?<=\1\2\1)", caseSensitive: false);
  execRE(re, "aabAaBa", ["aB", "aB", "a"]);

  re = new RegExp(r"(\w(\w))(?<=\1\2\1)", caseSensitive: false);
  execRE(re, "aabAaBa", ["Ba", "Ba", "a"]);

  re = new RegExp(r"(?=(\w))(?<=(\1)).", caseSensitive: false);
  execRE(re, "abaBbAa", ["b", "b", "B"]);

  re = new RegExp(r"(?<=(.))(\w+)(?=\1)");
  execRE(re, "  'foo'  ", ["foo", "'", "foo"]);
  execRE(re, "  \"foo\"  ", ["foo", "\"", "foo"]);
  testRE(re, "  .foo\"  ", false);

  re = new RegExp(r"(.)(?<=\1\1\1)");
  testRE(re, "ab", false);
  testRE(re, "abb", false);
  execRE(re, "abbb", ["b", "b"]);

  re = new RegExp(r"(..)(?<=\1\1\1)");
  testRE(re, "ab", false);
  testRE(re, "abb", false);
  testRE(re, "aabb", false);
  testRE(re, "abab", false);
  testRE(re, "fabxbab", false);
  testRE(re, "faxabab", false);
  execRE(re, "fababab", ["ab", "ab"]);

  // Back references to captures inside the lookbehind.
  re = new RegExp(r"(?<=\1(\w))d", caseSensitive: false);
  execRE(re, "abcCd", ["d", "C"]);

  re = new RegExp(r"(?<=\1([abx]))d");
  execRE(re, "abxxd", ["d", "x"]);

  re = new RegExp(r"(?<=\1(\w+))c");
  execRE(re, "ababc", ["c", "ab"]);
  execRE(re, "ababbc", ["c", "b"]);
  testRE(re, "ababdc", false);

  re = new RegExp(r"(?<=(\w+)\1)c");
  execRE(re, "ababc", ["c", "abab"]);

  // Alternations are tried left to right,
  // and we do not backtrack into a lookbehind.
  re = new RegExp(r".*(?<=(..|...|....))(.*)");
  execRE(re, "xabcd", ["xabcd", "cd", ""]);

  re = new RegExp(r".*(?<=(xx|...|....))(.*)");
  execRE(re, "xabcd", ["xabcd", "bcd", ""]);

  re = new RegExp(r".*(?<=(xx|...))(.*)");
  execRE(re, "xxabcd", ["xxabcd", "bcd", ""]);

  re = new RegExp(r".*(?<=(xx|xxx))(.*)");
  execRE(re, "xxabcd", ["xxabcd", "xx", "abcd"]);

  // We do not backtrack into a lookbehind.
  // The lookbehind captures "abc" so that \1 does not match. We do not backtrack
  // to capture only "bc" in the lookbehind.
  re = new RegExp(r"(?<=([abc]+)).\1");
  testRE(re, "abcdbc", false);

  // Greedy loop.
  re = new RegExp(r"(?<=(b+))c");
  execRE(re, "abbbbbbc", ["c", "bbbbbb"]);

  re = new RegExp(r"(?<=(b\d+))c");
  execRE(re, "ab1234c", ["c", "b1234"]);

  re = new RegExp(r"(?<=((?:b\d{2})+))c");
  execRE(re, "ab12b23b34c", ["c", "b12b23b34"]);

  // Sticky
  re = new RegExp(r"(?<=^(\w+))def");
  multiRE(re, "abcdefdef", [
    ["def", "abc"],
    ["def", "abcdef"]
  ]);

  re = new RegExp(r"\Bdef");
  multiRE(re, "abcdefdef", [
    ["def"],
    ["def"]
  ]);

  // Misc
  re = new RegExp(r"(?<=$abc)def");
  testRE(re, "abcdef", false);

  re = new RegExp(r"^foo(?<=foo)$");
  execRE(re, "foo", ["foo"]);

  re = new RegExp(r"^f.o(?<=foo)$");
  execRE(re, "foo", ["foo"]);

  re = new RegExp(r"^f.o(?<=foo)$");
  testRE(re, "fno", false);

  re = new RegExp(r"^foo(?<!foo)$");
  testRE(re, "foo", false);

  re = new RegExp(r"^f.o(?<!foo)$");
  testRE(re, "foo", false);
  execRE(re, "fno", ["fno"]);

  re = new RegExp(r"^foooo(?<=fo+)$");
  execRE(re, "foooo", ["foooo"]);

  re = new RegExp(r"^foooo(?<=fo*)$");
  execRE(re, "foooo", ["foooo"]);

  re = new RegExp(r"(abc\1)");
  execRE(re, "abc", ["abc", "abc"]);
  execRE(re, "abc\u1234", ["abc", "abc"]);

  re = new RegExp(r"(abc\1)", caseSensitive: false);
  execRE(re, "abc", ["abc", "abc"]);
  execRE(re, "abc\u1234", ["abc", "abc"]);

  final oob_subject = "abcdefghijklmnabcdefghijklmn".substring(14);
  re = new RegExp(r"(?=(abcdefghijklmn))(?<=\1)a", caseSensitive: false);
  testRE(re, oob_subject, false);

  re = new RegExp(r"(?=(abcdefghijklmn))(?<=\1)a");
  testRE(re, oob_subject, false);

  re = new RegExp(r"(?=(abcdefg))(?<=\1)");
  testRE(re, "abcdefgabcdefg".substring(1), false);

  // Mutual recursive capture/back references
  re = new RegExp(r"(?<=a(.\2)b(\1)).{4}");
  execRE(re, "aabcacbc", ["cacb", "a", ""]);

  re = new RegExp(r"(?<=a(\2)b(..\1))b");
  execRE(re, "aacbacb", ["b", "ac", "ac"]);

  re = new RegExp(r"(?<=(?:\1b)(aa)).");
  execRE(re, "aabaax", ["x", "aa"]);

  re = new RegExp(r"(?<=(?:\1|b)(aa)).");
  execRE(re, "aaaax", ["x", "aa"]);

  // Restricted syntax in Annex B 1.4.
  // The check for quantifiers on lookbehinds was added later than the
  // original feature in v8, so we may need to approve failures here
  // separately from the rest of the file.
  assertThrows(() => new RegExp(r"(?<=.)*")); //# 01: ok
  assertThrows(() => new RegExp(r"(?<=.)?")); //# 01: ok
  assertThrows(() => new RegExp(r"(?<=.)+")); //# 01: ok

  assertThrows(() => new RegExp(r"(?<=.)*", unicode: true)); //# 01: ok
  assertThrows(() => new RegExp(r"(?<=.){1,2}", unicode: true)); //# 01: ok
}
