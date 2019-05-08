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
  // Non-unicode use toUpperCase mappings.
  assertFalse(RegExp(r"[\u00e5]", caseSensitive: false).hasMatch("\u212b"));
  assertFalse(
      RegExp(r"[\u212b]", caseSensitive: false).hasMatch("\u00e5\u1234"));
  assertFalse(RegExp(r"[\u212b]", caseSensitive: false).hasMatch("\u00e5"));

  assertTrue("\u212b".toLowerCase() == "\u00e5");
  assertTrue("\u00c5".toLowerCase() == "\u00e5");
  assertTrue("\u00e5".toUpperCase() == "\u00c5");

  // Unicode uses case folding mappings.
  assertTrue(RegExp(r"\u00e5", caseSensitive: false, unicode: true)
      .hasMatch("\u212b"));
  assertTrue(RegExp(r"\u00e5", caseSensitive: false, unicode: true)
      .hasMatch("\u00c5"));
  assertTrue(RegExp(r"\u00e5", caseSensitive: false, unicode: true)
      .hasMatch("\u00e5"));
  assertTrue(RegExp(r"\u00e5", caseSensitive: false, unicode: true)
      .hasMatch("\u212b"));
  assertTrue(RegExp(r"\u00c5", caseSensitive: false, unicode: true)
      .hasMatch("\u00e5"));
  assertTrue(RegExp(r"\u00c5", caseSensitive: false, unicode: true)
      .hasMatch("\u212b"));
  assertTrue(RegExp(r"\u00c5", caseSensitive: false, unicode: true)
      .hasMatch("\u00c5"));
  assertTrue(RegExp(r"\u212b", caseSensitive: false, unicode: true)
      .hasMatch("\u00c5"));
  assertTrue(RegExp(r"\u212b", caseSensitive: false, unicode: true)
      .hasMatch("\u00e5"));
  assertTrue(RegExp(r"\u212b", caseSensitive: false, unicode: true)
      .hasMatch("\u212b"));

  // Non-BMP.
  assertFalse(RegExp(r"\u{10400}", caseSensitive: false).hasMatch("\u{10428}"));
  assertTrue(RegExp(r"\u{10400}", caseSensitive: false, unicode: true)
      .hasMatch("\u{10428}"));
  assertTrue(RegExp(r"\ud801\udc00", caseSensitive: false, unicode: true)
      .hasMatch("\u{10428}"));
  assertTrue(RegExp(r"[\u{10428}]", caseSensitive: false, unicode: true)
      .hasMatch("\u{10400}"));
  assertTrue(RegExp(r"[\ud801\udc28]", caseSensitive: false, unicode: true)
      .hasMatch("\u{10400}"));
  shouldBe(
      RegExp(r"[\uff40-\u{10428}]+", caseSensitive: false, unicode: true)
          .firstMatch("\uff21\u{10400}abc"),
      ["\uff21\u{10400}"]);
  shouldBe(
      RegExp(r"[^\uff40-\u{10428}]+", caseSensitive: false, unicode: true)
          .firstMatch("\uff21\u{10400}abc\uff23"),
      ["abc"]);
  shouldBe(
      RegExp(r"[\u24d5-\uff33]+", caseSensitive: false, unicode: true)
          .firstMatch("\uff54\uff53\u24bb\u24ba"),
      ["\uff53\u24bb"]);

  // Full mappings are ignored.
  assertFalse(
      RegExp(r"\u00df", caseSensitive: false, unicode: true).hasMatch("SS"));
  assertFalse(RegExp(r"\u1f8d", caseSensitive: false, unicode: true)
      .hasMatch("\u1f05\u03b9"));

  // Simple mappings work.
  assertTrue(RegExp(r"\u1f8d", caseSensitive: false, unicode: true)
      .hasMatch("\u1f85"));

  // Common mappings work.
  assertTrue(RegExp(r"\u1f6b", caseSensitive: false, unicode: true)
      .hasMatch("\u1f63"));

  // Back references.
  shouldBe(
      RegExp(r"(.)\1\1", caseSensitive: false, unicode: true)
          .firstMatch("\u00e5\u212b\u00c5"),
      ["\u00e5\u212b\u00c5", "\u00e5"]);
  shouldBe(
      RegExp(r"(.)\1", caseSensitive: false, unicode: true)
          .firstMatch("\u{118aa}\u{118ca}"),
      ["\u{118aa}\u{118ca}", "\u{118aa}"]);

  // Misc.
  assertTrue(RegExp(r"\u00e5\u00e5\u00e5", caseSensitive: false, unicode: true)
      .hasMatch("\u212b\u00e5\u00c5"));
  assertTrue(RegExp(r"AB\u{10400}", caseSensitive: false, unicode: true)
      .hasMatch("ab\u{10428}"));

  // Non-Latin1 maps to Latin1.
  shouldBe(
      RegExp(r"^\u017F", caseSensitive: false, unicode: true).firstMatch("s"),
      ["s"]);
  shouldBe(
      RegExp(r"^\u017F", caseSensitive: false, unicode: true)
          .firstMatch("s\u1234"),
      ["s"]);
  shouldBe(
      RegExp(r"^a[\u017F]", caseSensitive: false, unicode: true)
          .firstMatch("as"),
      ["as"]);
  shouldBe(
      RegExp(r"^a[\u017F]", caseSensitive: false, unicode: true)
          .firstMatch("as\u1234"),
      ["as"]);
}
