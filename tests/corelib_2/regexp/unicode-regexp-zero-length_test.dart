// Copyright (c) 2019, the Dart project authors. All rights reserved.
// Copyright 2016 the V8 project authors. All rights reserved.
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
  const L = "\ud800";
  const T = "\udc00";
  const x = "x";

  var r = RegExp(r"()"); // Not unicode.
  // Zero-length matches do not advance lastIndex.
  var m = r.matchAsPrefix(L + T + L + T);
  shouldBe(m, ["", ""]);
  assertEquals(0, m.end);

  m = r.matchAsPrefix(L + T + L + T, 1);
  shouldBe(m, ["", ""]);
  assertEquals(1, m.end);

  var u = RegExp(r"()", unicode: true);

  // Zero-length matches do not advance lastIndex (but do respect paired
  // surrogates).
  m = u.matchAsPrefix(L + T + L + T);
  shouldBe(m, ["", ""]);
  assertEquals(0, m.end);

  m = u.matchAsPrefix(L + T + L + T, 1);
  shouldBe(m, ["", ""]);
  assertEquals(0, m.end);

  // However, with repeating matches, we do advance from match to match.
  var ms = r.allMatches(L + T + L + T);
  assertEquals(5, ms.length);
  for (var i = 0; i < ms.length; i++) {
    shouldBe(ms.elementAt(i), ["", ""]);
  }

  // With unicode flag, we advance code point by code point.
  ms = u.allMatches(L + T + L + T);
  assertEquals(3, ms.length);
  for (var i = 0; i < ms.length; i++) {
    shouldBe(ms.elementAt(i), ["", ""]);
  }

  // Test with a lot of copies.
  const c = 100;
  ms = u.allMatches((L + T) * c);
  assertEquals(c + 1, ms.length);
  for (var i = 0; i < ms.length; i++) {
    shouldBe(ms.elementAt(i), ["", ""]);
  }

  // Same with replaceAll().
  assertEquals(
      x + L + x + T + x + L + x + T + x, (L + T + L + T).replaceAll(r, "x"));

  assertEquals(x + L + T + x + L + T + x, (L + T + L + T).replaceAll(u, "x"));

  assertEquals((x + L + T) * c + x, ((L + T) * c).replaceAll(u, "x"));

  // Also test String#split.
  Expect.deepEquals(
      ["\u{12345}"], "\u{12345}".split(RegExp(r"(?:)", unicode: true)));
}
