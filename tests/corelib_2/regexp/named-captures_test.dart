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

  void namedRE(RegExp re, String input, Map<String, String> expectedResults) {
    assertTrue(re.hasMatch(input));
    var match = re.firstMatch(input) as RegExpMatch;
    for (var s in expectedResults.keys) {
      assertEquals(match.namedGroup(s), expectedResults[s]);
    }
  }

  void hasNames(RegExp re, String input, List<String> expectedResults) {
    assertTrue(re.hasMatch(input));
    var match = re.firstMatch(input) as RegExpMatch;
    for (var s in match.groupNames) {
      assertTrue(expectedResults.contains(s));
    }
  }

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

  // TODO(sstrickl): Add more tests when unicode flag support is in.
  // https://github.com/dart-lang/sdk/issues/36170
}
