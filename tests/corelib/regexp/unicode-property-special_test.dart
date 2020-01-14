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
  void t(RegExp re, String s) {
    assertTrue(re.hasMatch(s));
  }

  void f(RegExp re, String s) {
    assertFalse(re.hasMatch(s));
  }

  t(RegExp(r"\p{ASCII}+", unicode: true), "abc123");
  f(RegExp(r"\p{ASCII}+", unicode: true), "ⓐⓑⓒ①②③");
  f(RegExp(r"\p{ASCII}+", unicode: true), "🄰🄱🄲①②③");
  f(RegExp(r"\P{ASCII}+", unicode: true), "abcd123");
  t(RegExp(r"\P{ASCII}+", unicode: true), "ⓐⓑⓒ①②③");
  t(RegExp(r"\P{ASCII}+", unicode: true), "🄰🄱🄲①②③");

  f(RegExp(r"[^\p{ASCII}]+", unicode: true), "abc123");
  f(RegExp(r"[\p{ASCII}]+", unicode: true), "ⓐⓑⓒ①②③");
  f(RegExp(r"[\p{ASCII}]+", unicode: true), "🄰🄱🄲①②③");
  t(RegExp(r"[^\P{ASCII}]+", unicode: true), "abcd123");
  t(RegExp(r"[\P{ASCII}]+", unicode: true), "ⓐⓑⓒ①②③");
  f(RegExp(r"[^\P{ASCII}]+", unicode: true), "🄰🄱🄲①②③");

  t(RegExp(r"\p{Any}+", unicode: true), "🄰🄱🄲①②③");

  shouldBe(
      RegExp(r"\p{Any}", unicode: true).firstMatch("\ud800\ud801"), ["\ud800"]);
  shouldBe(
      RegExp(r"\p{Any}", unicode: true).firstMatch("\udc00\udc01"), ["\udc00"]);
  shouldBe(RegExp(r"\p{Any}", unicode: true).firstMatch("\ud800\udc01"),
      ["\ud800\udc01"]);
  shouldBe(RegExp(r"\p{Any}", unicode: true).firstMatch("\udc01"), ["\udc01"]);

  f(RegExp(r"\P{Any}+", unicode: true), "123");
  f(RegExp(r"[\P{Any}]+", unicode: true), "123");
  t(RegExp(r"[\P{Any}\d]+", unicode: true), "123");
  t(RegExp(r"[^\P{Any}]+", unicode: true), "123");

  t(RegExp(r"\p{Assigned}+", unicode: true), "123");
  t(RegExp(r"\p{Assigned}+", unicode: true), "🄰🄱🄲");
  f(RegExp(r"\p{Assigned}+", unicode: true), "\ufdd0");
  f(RegExp(r"\p{Assigned}+", unicode: true), "\u{fffff}");

  f(RegExp(r"\P{Assigned}+", unicode: true), "123");
  f(RegExp(r"\P{Assigned}+", unicode: true), "🄰🄱🄲");
  t(RegExp(r"\P{Assigned}+", unicode: true), "\ufdd0");
  t(RegExp(r"\P{Assigned}+", unicode: true), "\u{fffff}");
  f(RegExp(r"\P{Assigned}", unicode: true), "");

  t(RegExp(r"[^\P{Assigned}]+", unicode: true), "123");
  f(RegExp(r"[\P{Assigned}]+", unicode: true), "🄰🄱🄲");
  f(RegExp(r"[^\P{Assigned}]+", unicode: true), "\ufdd0");
  t(RegExp(r"[\P{Assigned}]+", unicode: true), "\u{fffff}");
  f(RegExp(r"[\P{Assigned}]", unicode: true), "");

  f(RegExp(r"[^\u1234\p{ASCII}]+", unicode: true), "\u1234");
  t(RegExp(r"[x\P{ASCII}]+", unicode: true), "x");
  t(RegExp(r"[\u1234\p{ASCII}]+", unicode: true), "\u1234");

// Contributory binary properties are not supported.
  assertThrows(() => RegExp("\\p{Other_Alphabetic}", unicode: true));
  assertThrows(() => RegExp("\\P{OAlpha}", unicode: true));
  assertThrows(
      () => RegExp("\\p{Other_Default_Ignorable_Code_Point}", unicode: true));
  assertThrows(() => RegExp("\\P{ODI}", unicode: true));
  assertThrows(() => RegExp("\\p{Other_Grapheme_Extend}", unicode: true));
  assertThrows(() => RegExp("\\P{OGr_Ext}", unicode: true));
  assertThrows(() => RegExp("\\p{Other_ID_Continue}", unicode: true));
  assertThrows(() => RegExp("\\P{OIDC}", unicode: true));
  assertThrows(() => RegExp("\\p{Other_ID_Start}", unicode: true));
  assertThrows(() => RegExp("\\P{OIDS}", unicode: true));
  assertThrows(() => RegExp("\\p{Other_Lowercase}", unicode: true));
  assertThrows(() => RegExp("\\P{OLower}", unicode: true));
  assertThrows(() => RegExp("\\p{Other_Math}", unicode: true));
  assertThrows(() => RegExp("\\P{OMath}", unicode: true));
  assertThrows(() => RegExp("\\p{Other_Uppercase}", unicode: true));
  assertThrows(() => RegExp("\\P{OUpper}", unicode: true));
}
