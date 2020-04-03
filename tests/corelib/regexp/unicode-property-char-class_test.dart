// Copyright (c) 2019, the Dart project authors. All rights reserved.
// Copyright 2011 the V8 project authors. All rights reserved.
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
  assertThrows(() => RegExp("[\\p]", unicode: true));
  assertThrows(() => RegExp("[\\p{garbage}]", unicode: true));
  assertThrows(() => RegExp("[\\p{}]", unicode: true));
  assertThrows(() => RegExp("[\\p{]", unicode: true));
  assertThrows(() => RegExp("[\\p}]", unicode: true));
  assertThrows(() => RegExp("^[\\p{Lu}-\\p{Ll}]+\$", unicode: true));

  assertTrue(RegExp(r"^[\p{Lu}\p{Ll}]+$", unicode: true).hasMatch("ABCabc"));
  assertTrue(RegExp(r"^[\p{Lu}-]+$", unicode: true).hasMatch("ABC-"));
  assertFalse(RegExp(r"^[\P{Lu}\p{Ll}]+$", unicode: true).hasMatch("ABCabc"));
  assertTrue(RegExp(r"^[\P{Lu}\p{Ll}]+$", unicode: true).hasMatch("abc"));
  assertTrue(RegExp(r"^[\P{Lu}]+$", unicode: true).hasMatch("abc123"));
  assertFalse(RegExp(r"^[\P{Lu}]+$", unicode: true).hasMatch("XYZ"));
  assertTrue(RegExp(r"[\p{Math}]", unicode: true).hasMatch("+"));
  assertTrue(RegExp(r"[\P{Bidi_M}]", unicode: true).hasMatch(" "));
  assertTrue(RegExp(r"[\p{Hex}]", unicode: true).hasMatch("A"));

  assertTrue(RegExp(r"^[^\P{Lu}]+$", unicode: true).hasMatch("XYZ"));
  assertFalse(RegExp(r"^[^\p{Lu}\p{Ll}]+$", unicode: true).hasMatch("abc"));
  assertFalse(RegExp(r"^[^\p{Lu}\p{Ll}]+$", unicode: true).hasMatch("ABC"));
  assertTrue(RegExp(r"^[^\p{Lu}\p{Ll}]+$", unicode: true).hasMatch("123"));
  assertTrue(RegExp(r"^[^\p{Lu}\P{Ll}]+$", unicode: true).hasMatch("abc"));
}
