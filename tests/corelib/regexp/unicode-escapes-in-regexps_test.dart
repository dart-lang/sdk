// Copyright (c) 2019, the Dart project authors. All rights reserved.
// Copyright 2014 the V8 project authors. All rights reserved.
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
//
// ES6 extends the \uxxxx escape and also allows \u{xxxxx}.

import 'package:expect/expect.dart';

import 'v8_regexp_utils.dart';

void testRegExpHelper(RegExp r) {
  assertTrue(r.hasMatch("foo"));
  assertTrue(r.hasMatch("boo"));
  assertFalse(r.hasMatch("moo"));
}

void TestUnicodeEscapes() {
  testRegExpHelper(RegExp(r"(\u0066|\u0062)oo"));
  testRegExpHelper(RegExp(r"(\u0066|\u0062)oo", unicode: true));
  testRegExpHelper(RegExp(r"(\u{0066}|\u{0062})oo", unicode: true));
  testRegExpHelper(RegExp(r"(\u{66}|\u{000062})oo", unicode: true));

  // Note that we need \\ inside a string, otherwise it's interpreted as a
  // unicode escape inside a string.
  testRegExpHelper(RegExp("(\\u0066|\\u0062)oo"));
  testRegExpHelper(RegExp("(\\u0066|\\u0062)oo", unicode: true));
  testRegExpHelper(RegExp("(\\u{0066}|\\u{0062})oo", unicode: true));
  testRegExpHelper(RegExp("(\\u{66}|\\u{000062})oo", unicode: true));

  // Though, unicode escapes via strings should work too.
  testRegExpHelper(RegExp("(\u0066|\u0062)oo"));
  testRegExpHelper(RegExp("(\u0066|\u0062)oo", unicode: true));
  testRegExpHelper(RegExp("(\u{0066}|\u{0062})oo", unicode: true));
  testRegExpHelper(RegExp("(\u{66}|\u{000062})oo", unicode: true));
}

void TestUnicodeEscapesInCharacterClasses() {
  testRegExpHelper(RegExp(r"[\u0062-\u0066]oo"));
  testRegExpHelper(RegExp(r"[\u0062-\u0066]oo", unicode: true));
  testRegExpHelper(RegExp(r"[\u{0062}-\u{0066}]oo", unicode: true));
  testRegExpHelper(RegExp(r"[\u{62}-\u{000066}]oo", unicode: true));

  // Note that we need \\ inside a string, otherwise it's interpreted as a
  // unicode escape inside a string.
  testRegExpHelper(RegExp("[\\u0062-\\u0066]oo"));
  testRegExpHelper(RegExp("[\\u0062-\\u0066]oo", unicode: true));
  testRegExpHelper(RegExp("[\\u{0062}-\\u{0066}]oo", unicode: true));
  testRegExpHelper(RegExp("[\\u{62}-\\u{000066}]oo", unicode: true));

  // Though, unicode escapes via strings should work too.
  testRegExpHelper(RegExp("[\u0062-\u0066]oo"));
  testRegExpHelper(RegExp("[\u0062-\u0066]oo", unicode: true));
  testRegExpHelper(RegExp("[\u{0062}-\u{0066}]oo", unicode: true));
  testRegExpHelper(RegExp("[\u{62}-\u{000066}]oo", unicode: true));
}

void TestBraceEscapesWithoutUnicodeFlag() {
  // \u followed by illegal escape will be parsed as u. {x} will be the
  // character count.
  void helper1(RegExp r) {
    assertFalse(r.hasMatch("fbar"));
    assertFalse(r.hasMatch("fubar"));
    assertTrue(r.hasMatch("fuubar"));
    assertFalse(r.hasMatch("fuuubar"));
  }

  helper1(RegExp(r"f\u{2}bar"));
  helper1(RegExp("f\\u{2}bar"));

  void helper2(RegExp r) {
    assertFalse(r.hasMatch("fbar"));
    assertTrue(r.hasMatch("fubar"));
    assertTrue(r.hasMatch("fuubar"));
    assertFalse(r.hasMatch("fuuubar"));
  }

  helper2(RegExp(r"f\u{1,2}bar"));
  helper2(RegExp("f\\u{1,2}bar"));

  void helper3(RegExp r) {
    assertTrue(r.hasMatch("u"));
    assertTrue(r.hasMatch("{"));
    assertTrue(r.hasMatch("2"));
    assertTrue(r.hasMatch("}"));
    assertFalse(r.hasMatch("q"));
    assertFalse(r.hasMatch("("));
    assertFalse(r.hasMatch(")"));
  }

  helper3(RegExp(r"[\u{2}]"));
  helper3(RegExp("[\\u{2}]"));
}

void TestInvalidEscapes() {
  // Without the u flag, invalid unicode escapes and other invalid escapes are
  // treated as identity escapes.
  void helper1(RegExp r) {
    assertTrue(r.hasMatch("firstuxz89second"));
  }

  helper1(RegExp(r"first\u\x\z\8\9second"));
  helper1(RegExp("first\\u\\x\\z\\8\\9second"));

  void helper2(RegExp r) {
    assertTrue(r.hasMatch("u"));
    assertTrue(r.hasMatch("x"));
    assertTrue(r.hasMatch("z"));
    assertTrue(r.hasMatch("8"));
    assertTrue(r.hasMatch("9"));
    assertFalse(r.hasMatch("q"));
    assertFalse(r.hasMatch("7"));
  }

  helper2(RegExp(r"[\u\x\z\8\9]"));
  helper2(RegExp("[\\u\\x\\z\\8\\9]"));

  // However, with the u flag, these are treated as invalid escapes.
  assertThrows(() => RegExp(r"\u", unicode: true));
  assertThrows(() => RegExp(r"\u12", unicode: true));
  assertThrows(() => RegExp(r"\ufoo", unicode: true));
  assertThrows(() => RegExp(r"\x", unicode: true));
  assertThrows(() => RegExp(r"\xfoo", unicode: true));
  assertThrows(() => RegExp(r"\z", unicode: true));
  assertThrows(() => RegExp(r"\8", unicode: true));
  assertThrows(() => RegExp(r"\9", unicode: true));

  assertThrows(() => RegExp("\\u", unicode: true));
  assertThrows(() => RegExp("\\u12", unicode: true));
  assertThrows(() => RegExp("\\ufoo", unicode: true));
  assertThrows(() => RegExp("\\x", unicode: true));
  assertThrows(() => RegExp("\\xfoo", unicode: true));
  assertThrows(() => RegExp("\\z", unicode: true));
  assertThrows(() => RegExp("\\8", unicode: true));
  assertThrows(() => RegExp("\\9", unicode: true));
}

void TestTooBigHexEscape() {
  // The hex number inside \u{} has a maximum value.
  RegExp(r"\u{10ffff}", unicode: true);
  RegExp("\\u{10ffff}", unicode: true);
  assertThrows(() => RegExp(r"\u{110000}", unicode: true));
  assertThrows(() => RegExp("\\u{110000}", unicode: true));

  // Without the u flag, they're of course fine ({x} is the count).
  RegExp(r"\u{110000}");
  RegExp("\\u{110000}");
}

void TestSyntaxEscapes() {
  // Syntax escapes work the same with or without the u flag.
  void helper(RegExp r) {
    assertTrue(r.hasMatch("foo[bar"));
    assertFalse(r.hasMatch("foo]bar"));
  }

  helper(RegExp(r"foo\[bar"));
  helper(RegExp("foo\\[bar"));
  helper(RegExp(r"foo\[bar", unicode: true));
  helper(RegExp("foo\\[bar", unicode: true));
}

void TestUnicodeSurrogates() {
  // U+10E6D corresponds to the surrogate pair [U+D803, U+DE6D].
  void helper(RegExp r) {
    assertTrue(r.hasMatch("foo\u{10e6d}bar"));
  }

  helper(RegExp(r"foo\ud803\ude6dbar", unicode: true));
  helper(RegExp("foo\\ud803\\ude6dbar", unicode: true));
}

void main() {
  TestUnicodeEscapes();
  TestUnicodeEscapesInCharacterClasses();
  TestBraceEscapesWithoutUnicodeFlag();
  TestInvalidEscapes();
  TestTooBigHexEscape();
  TestSyntaxEscapes();
  TestUnicodeSurrogates();

  // Non-BMP patterns.
  // Single character atom.
  assertTrue(RegExp("\u{12345}", unicode: true).hasMatch("\u{12345}"));
  assertTrue(RegExp(r"\u{12345}", unicode: true).hasMatch("\u{12345}"));
  assertTrue(RegExp(r"\u{12345}", unicode: true).hasMatch("\ud808\udf45"));
  assertTrue(RegExp(r"\u{12345}", unicode: true).hasMatch("\ud808\udf45"));
  assertFalse(RegExp(r"\u{12345}", unicode: true).hasMatch("\udf45"));
  assertFalse(RegExp(r"\u{12345}", unicode: true).hasMatch("\udf45"));

  // Multi-character atom.
  assertTrue(RegExp(r"\u{12345}\u{23456}", unicode: true)
      .hasMatch("a\u{12345}\u{23456}b"));
  assertTrue(RegExp(r"\u{12345}\u{23456}", unicode: true)
      .hasMatch("b\u{12345}\u{23456}c"));
  assertFalse(RegExp(r"\u{12345}\u{23456}", unicode: true)
      .hasMatch("a\udf45\u{23456}b"));
  assertFalse(RegExp(r"\u{12345}\u{23456}", unicode: true)
      .hasMatch("b\udf45\u{23456}c"));

  // Disjunction.
  assertTrue(RegExp(r"\u{12345}(?:\u{23456})", unicode: true)
      .hasMatch("a\u{12345}\u{23456}b"));
  assertTrue(RegExp(r"\u{12345}(?:\u{23456})", unicode: true)
      .hasMatch("b\u{12345}\u{23456}c"));
  assertFalse(RegExp(r"\u{12345}(?:\u{23456})", unicode: true)
      .hasMatch("a\udf45\u{23456}b"));
  assertFalse(RegExp(r"\u{12345}(?:\u{23456})", unicode: true)
      .hasMatch("b\udf45\u{23456}c"));

  // Alternative.
  assertTrue(
      RegExp(r"\u{12345}|\u{23456}", unicode: true).hasMatch("a\u{12345}b"));
  assertTrue(
      RegExp(r"\u{12345}|\u{23456}", unicode: true).hasMatch("b\u{23456}c"));
  assertFalse(
      RegExp(r"\u{12345}|\u{23456}", unicode: true).hasMatch("a\udf45\ud84db"));
  assertFalse(
      RegExp(r"\u{12345}|\u{23456}", unicode: true).hasMatch("b\udf45\ud808c"));

  // Capture.
  assertTrue(RegExp("(\u{12345}|\u{23456}).\\1", unicode: true)
      .hasMatch("\u{12345}b\u{12345}"));
  assertTrue(RegExp(r"(\u{12345}|\u{23456}).\1", unicode: true)
      .hasMatch("\u{12345}b\u{12345}"));
  assertFalse(RegExp("(\u{12345}|\u{23456}).\\1", unicode: true)
      .hasMatch("\u{12345}b\u{23456}"));
  assertFalse(RegExp(r"(\u{12345}|\u{23456}).\1", unicode: true)
      .hasMatch("\u{12345}b\u{23456}"));

  // Quantifier.
  assertTrue(RegExp("\u{12345}{3}", unicode: true)
      .hasMatch("\u{12345}\u{12345}\u{12345}"));
  assertTrue(RegExp(r"\u{12345}{3}", unicode: true)
      .hasMatch("\u{12345}\u{12345}\u{12345}"));
  assertTrue(RegExp("\u{12345}{3}").hasMatch("\u{12345}\udf45\udf45"));
  assertFalse(RegExp(r"\ud808\udf45{3}", unicode: true)
      .hasMatch("\u{12345}\udf45\udf45"));
  assertTrue(RegExp(r"\ud808\udf45{3}", unicode: true)
      .hasMatch("\u{12345}\u{12345}\u{12345}"));
  assertFalse(
      RegExp("\u{12345}{3}", unicode: true).hasMatch("\u{12345}\udf45\udf45"));
  assertFalse(
      RegExp(r"\u{12345}{3}", unicode: true).hasMatch("\u{12345}\udf45\udf45"));

  // Literal surrogates.
  shouldBe(
      RegExp("\ud800\udc00+", unicode: true).firstMatch("\u{10000}\u{10000}"),
      ["\u{10000}\u{10000}"]);
  shouldBe(
      RegExp("\\ud800\\udc00+", unicode: true).firstMatch("\u{10000}\u{10000}"),
      ["\u{10000}\u{10000}"]);

  shouldBe(
      RegExp("[\\ud800\\udc03-\\ud900\\udc01\]+", unicode: true)
          .firstMatch("\u{10003}\u{50001}"),
      ["\u{10003}\u{50001}"]);
  shouldBe(
      RegExp("[\ud800\udc03-\u{50001}\]+", unicode: true)
          .firstMatch("\u{10003}\u{50001}"),
      ["\u{10003}\u{50001}"]);

  // Unicode escape sequences to represent a non-BMP character cannot have
  // mixed notation, and must follow the rules for RegExpUnicodeEscapeSequence.
  assertThrows(() => RegExp("[\\ud800\udc03-\ud900\\udc01\]+", unicode: true));
  assertNull(
      RegExp("\\ud800\udc00+", unicode: true).firstMatch("\u{10000}\u{10000}"));
  assertNull(
      RegExp("\ud800\\udc00+", unicode: true).firstMatch("\u{10000}\u{10000}"));

  assertNull(RegExp("[\\ud800\udc00]", unicode: true).firstMatch("\u{10000}"));
  assertNull(
      RegExp("[\\{ud800}\udc00]", unicode: true).firstMatch("\u{10000}"));
  assertNull(RegExp("[\ud800\\udc00]", unicode: true).firstMatch("\u{10000}"));
  assertNull(
      RegExp("[\ud800\\{udc00}]", unicode: true).firstMatch("\u{10000}"));

  assertNull(RegExp(r"\u{d800}\u{dc00}+", unicode: true)
      .firstMatch("\ud800\udc00\udc00"));
  assertNull(RegExp(r"\ud800\u{dc00}+", unicode: true)
      .firstMatch("\ud800\udc00\udc00"));
  assertNull(RegExp(r"\u{d800}\udc00+", unicode: true)
      .firstMatch("\ud800\udc00\udc00"));
}
