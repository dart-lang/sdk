// Copyright (c) 2014, the Dart project authors. All rights reserved.
// Copyright 2008 the V8 project authors. All rights reserved.
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
  dynamic CheckMatch(re, str, matches) {
    assertEquals(matches.length > 0, re.hasMatch(str));
    var result = re.allMatches(str).toList();
    if (matches.length > 0) {
      assertEquals(matches.length, result.length);
      var lastExpected;
      var lastFrom;
      var lastLength;
      for (var idx = 0; idx < matches.length; idx++) {
        var from = matches[idx][0];
        var length = matches[idx][1];
        var expected = str.substring(from, from + length);
        var name = "$str[$from..${from+length}]";
        assertEquals(expected, result[idx].group(0), name);
      }
    } else {
      assertTrue(result.isEmpty);
    }
  }

  CheckMatch(new RegExp(r"abc"), "xxxabcxxxabcxxx", [
    [3, 3],
    [9, 3]
  ]);
  CheckMatch(new RegExp(r"abc"), "abcabcabc", [
    [0, 3],
    [3, 3],
    [6, 3]
  ]);
  CheckMatch(new RegExp(r"aba"), "ababababa", [
    [0, 3],
    [4, 3]
  ]);
  CheckMatch(new RegExp(r"foo"), "ofooofoooofofooofo", [
    [1, 3],
    [5, 3],
    [12, 3]
  ]);
  CheckMatch(new RegExp(r"foobarbaz"), "xx", []);
  CheckMatch(new RegExp(r"abc"), "abababa", []);

  assertEquals("xxxdefxxxdefxxx",
      "xxxabcxxxabcxxx".replaceAll(new RegExp(r"abc"), "def"));
  assertEquals(
      "o-o-oofo-ofo", "ofooofoooofofooofo".replaceAll(new RegExp(r"foo"), "-"));
  assertEquals("deded", "deded".replaceAll(new RegExp(r"x"), "-"));
  assertEquals("-a-b-c-d-e-f-", "abcdef".replaceAll(new RegExp(""), "-"));

  CheckMatch(new RegExp(r"a(.)"), "xyzzyabxyzzyacxyzzy", [
    [5, 2],
    [12, 2]
  ]);

  CheckMatch(new RegExp(r"a|(?:)"), "aba", [
    [0, 1],
    [1, 0],
    [2, 1],
    [3, 0]
  ]);
  CheckMatch(new RegExp(r"a|(?:)"), "baba", [
    [0, 0],
    [1, 1],
    [2, 0],
    [3, 1],
    [4, 0]
  ]);
  CheckMatch(new RegExp(r"a|(?:)"), "bab", [
    [0, 0],
    [1, 1],
    [2, 0],
    [3, 0]
  ]);
}
