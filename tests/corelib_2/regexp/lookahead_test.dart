// Copyright (c) 2014, the Dart project authors. All rights reserved.
// Copyright 2009 the V8 project authors. All rights reserved.
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

import 'v8_regexp_utils.dart';
import 'package:expect/expect.dart';

void main() {
  // Tests captures in positive and negative look-ahead in regular expressions.

  dynamic testRE(re, input, expected_result) {
    if (expected_result) {
      assertTrue(re.hasMatch(input));
    } else {
      assertFalse(re.hasMatch(input));
    }
  }

  dynamic execRE(re, input, expected_result) {
    shouldBe(re.firstMatch(input), expected_result);
  }

  // Test of simple positive lookahead.

  var re = new RegExp(r"^(?=a)");
  testRE(re, "a", true);
  testRE(re, "b", false);
  execRE(re, "a", [""]);

  re = new RegExp(r"^(?=\woo)f\w");
  testRE(re, "foo", true);
  testRE(re, "boo", false);
  testRE(re, "fao", false);
  testRE(re, "foa", false);
  execRE(re, "foo", ["fo"]);

  re = new RegExp(r"(?=\w).(?=\W)");
  testRE(re, ".a! ", true);
  testRE(re, ".! ", false);
  testRE(re, ".ab! ", true);
  execRE(re, ".ab! ", ["b"]);

  re = new RegExp(r"(?=f(?=[^f]o))..");
  testRE(re, ", foo!", true);
  testRE(re, ", fo!", false);
  testRE(re, ", ffo", false);
  execRE(re, ", foo!", ["fo"]);

  // Positive lookahead with captures.
  re = new RegExp("^[^\'\"]*(?=([\'\"])).*\\1(\\w+)\\1");
  testRE(re, "  'foo' ", true);
  testRE(re, '  "foo" ', true);
  testRE(re, " \" 'foo' ", false);
  testRE(re, " ' \"foo\" ", false);
  testRE(re, "  'foo\" ", false);
  testRE(re, "  \"foo' ", false);
  execRE(re, "  'foo' ", ["  'foo'", "'", "foo"]);
  execRE(re, '  "foo" ', ['  "foo"', '"', 'foo']);

  // Captures are cleared on backtrack past the look-ahead.
  re = new RegExp(r"^(?:(?=(.))a|b)\1$");
  testRE(re, "aa", true);
  testRE(re, "b", true);
  testRE(re, "bb", false);
  testRE(re, "a", false);
  execRE(re, "aa", ["aa", "a"]);
  execRE(re, "b", ["b", null]);

  re = new RegExp(r"^(?=(.)(?=(.)\1\2)\2\1)\1\2");
  testRE(re, "abab", true);
  testRE(re, "ababxxxxxxxx", true);
  testRE(re, "aba", false);
  execRE(re, "abab", ["ab", "a", "b"]);

  re = new RegExp(r"^(?:(?=(.))a|b|c)$");
  testRE(re, "a", true);
  testRE(re, "b", true);
  testRE(re, "c", true);
  testRE(re, "d", false);
  execRE(re, "a", ["a", "a"]);
  execRE(re, "b", ["b", null]);
  execRE(re, "c", ["c", null]);

  execRE(new RegExp(r"^(?=(b))b"), "b", ["b", "b"]);
  execRE(new RegExp(r"^(?:(?=(b))|a)b"), "ab", ["ab", null]);
  execRE(new RegExp(r"^(?:(?=(b)(?:(?=(c))|d))|)bd"), "bd", ["bd", "b", null]);

  // Test of Negative Look-Ahead.

  re = new RegExp(r"(?!x).");
  testRE(re, "y", true);
  testRE(re, "x", false);
  execRE(re, "y", ["y"]);

  re = new RegExp(r"(?!(\d))|\d");
  testRE(re, "4", true);
  execRE(re, "4", ["4", null]);
  execRE(re, "x", ["", null]);

  // Test mixed nested look-ahead with captures.

  re = new RegExp(r"^(?=(x)(?=(y)))");
  testRE(re, "xy", true);
  testRE(re, "xz", false);
  execRE(re, "xy", ["", "x", "y"]);

  re = new RegExp(r"^(?!(x)(?!(y)))");
  testRE(re, "xy", true);
  testRE(re, "xz", false);
  execRE(re, "xy", ["", null, null]);

  re = new RegExp(r"^(?=(x)(?!(y)))");
  testRE(re, "xz", true);
  testRE(re, "xy", false);
  execRE(re, "xz", ["", "x", null]);

  re = new RegExp(r"^(?!(x)(?=(y)))");
  testRE(re, "xz", true);
  testRE(re, "xy", false);
  execRE(re, "xz", ["", null, null]);

  re = new RegExp(r"^(?=(x)(?!(y)(?=(z))))");
  testRE(re, "xaz", true);
  testRE(re, "xya", true);
  testRE(re, "xyz", false);
  testRE(re, "a", false);
  execRE(re, "xaz", ["", "x", null, null]);
  execRE(re, "xya", ["", "x", null, null]);

  re = new RegExp(r"^(?!(x)(?=(y)(?!(z))))");
  testRE(re, "a", true);
  testRE(re, "xa", true);
  testRE(re, "xyz", true);
  testRE(re, "xya", false);
  execRE(re, "a", ["", null, null, null]);
  execRE(re, "xa", ["", null, null, null]);
  execRE(re, "xyz", ["", null, null, null]);
}
