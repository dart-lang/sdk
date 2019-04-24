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
  // test262/data/test/language/literals/regexp/u-dec-esc
  assertThrows(() => RegExp(r"\1", unicode: true));
  // test262/language/literals/regexp/u-invalid-char-range-a
  assertThrows(() => RegExp(r"[\w-a]", unicode: true));
  // test262/language/literals/regexp/u-invalid-char-range-b
  assertThrows(() => RegExp(r"[a-\w]", unicode: true));
  // test262/language/literals/regexp/u-invalid-char-esc
  assertThrows(() => RegExp(r"\c", unicode: true));
  assertThrows(() => RegExp(r"\c0", unicode: true));
  // test262/built-ins/RegExp/unicode_restricted_quantifiable_assertion
  assertThrows(() => RegExp(r"(?=.)*", unicode: true));
  assertThrows(() => RegExp(r"(?=.){1,2}", unicode: true));
  // test262/built-ins/RegExp/unicode_restricted_octal_escape
  assertThrows(() => RegExp(r"[\1]", unicode: true));
  assertThrows(() => RegExp(r"\00", unicode: true));
  assertThrows(() => RegExp(r"\09", unicode: true));
  // test262/built-ins/RegExp/unicode_restricted_identity_escape_alpha
  assertThrows(() => RegExp(r"[\c]", unicode: true));
  // test262/built-ins/RegExp/unicode_restricted_identity_escape_c
  assertThrows(() => RegExp(r"[\c0]", unicode: true));
  // test262/built-ins/RegExp/unicode_restricted_incomple_quantifier
  assertThrows(() => RegExp(r"a{", unicode: true));
  assertThrows(() => RegExp(r"a{1,", unicode: true));
  assertThrows(() => RegExp(r"{", unicode: true));
  assertThrows(() => RegExp(r"}", unicode: true));
  // test262/data/test/built-ins/RegExp/unicode_restricted_brackets
  assertThrows(() => RegExp(r"]", unicode: true));
  // test262/built-ins/RegExp/unicode_identity_escape
  assertDoesNotThrow(() => RegExp(r"\/", unicode: true));

  // escaped \0 (as NUL) is allowed inside a character class.
  shouldBe(RegExp(r"[\0]", unicode: true).firstMatch("\u0000"), ["\u0000"]);
  // unless it is followed by another digit.
  assertThrows(() => RegExp(r"[\00]", unicode: true));
  assertThrows(() => RegExp(r"[\01]", unicode: true));
  assertThrows(() => RegExp(r"[\09]", unicode: true));
  shouldBe(RegExp(r"[1\0a]+", unicode: true).firstMatch("b\u{0}1\u{0}a\u{0}2"),
      ["\u{0}1\u{0}a\u{0}"]);
  // escaped \- is allowed inside a character class.
  shouldBe(RegExp(r"[a\-z]", unicode: true).firstMatch("12-34"), ["-"]);
}
