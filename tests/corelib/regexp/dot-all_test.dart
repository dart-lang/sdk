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
  // The flags accessors.
  var re = new RegExp(r".", dotAll: true);
  assertTrue(re.isCaseSensitive);
  assertFalse(re.isMultiLine);
  assertFalse(re.isUnicode);
  assertTrue(re.isDotAll);

  re = new RegExp(r".",
      caseSensitive: false, multiLine: true, unicode: true, dotAll: true);
  assertFalse(re.isCaseSensitive);
  assertTrue(re.isMultiLine);
  assertTrue(re.isUnicode);
  assertTrue(re.isDotAll);

  re = new RegExp(r".", caseSensitive: false, multiLine: true, unicode: true);
  assertFalse(re.isCaseSensitive);
  assertTrue(re.isMultiLine);
  assertTrue(re.isUnicode);
  assertFalse(re.isDotAll);

  // Default '.' behavior.
  re = new RegExp(r"^.$");
  assertTrue(re.hasMatch("a"));
  assertTrue(re.hasMatch("3"));
  assertTrue(re.hasMatch("π"));
  assertTrue(re.hasMatch("\u2027"));
  assertTrue(re.hasMatch("\u0085"));
  assertTrue(re.hasMatch("\v"));
  assertTrue(re.hasMatch("\f"));
  assertTrue(re.hasMatch("\u180E"));
  assertFalse(re.hasMatch("\u{10300}")); // Supplementary plane.
  assertFalse(re.hasMatch("\n"));
  assertFalse(re.hasMatch("\r"));
  assertFalse(re.hasMatch("\u2028"));
  assertFalse(re.hasMatch("\u2029"));

  // Default '.' behavior (unicode).
  re = new RegExp(r"^.$", unicode: true);
  assertTrue(re.hasMatch("a"));
  assertTrue(re.hasMatch("3"));
  assertTrue(re.hasMatch("π"));
  assertTrue(re.hasMatch("\u2027"));
  assertTrue(re.hasMatch("\u0085"));
  assertTrue(re.hasMatch("\v"));
  assertTrue(re.hasMatch("\f"));
  assertTrue(re.hasMatch("\u180E"));
  assertTrue(re.hasMatch("\u{10300}")); // Supplementary plane.
  assertFalse(re.hasMatch("\n"));
  assertFalse(re.hasMatch("\r"));
  assertFalse(re.hasMatch("\u2028"));
  assertFalse(re.hasMatch("\u2029"));

  // DotAll '.' behavior.
  re = new RegExp(r"^.$", dotAll: true);
  assertTrue(re.hasMatch("a"));
  assertTrue(re.hasMatch("3"));
  assertTrue(re.hasMatch("π"));
  assertTrue(re.hasMatch("\u2027"));
  assertTrue(re.hasMatch("\u0085"));
  assertTrue(re.hasMatch("\v"));
  assertTrue(re.hasMatch("\f"));
  assertTrue(re.hasMatch("\u180E"));
  assertFalse(re.hasMatch("\u{10300}")); // Supplementary plane.
  assertTrue(re.hasMatch("\n"));
  assertTrue(re.hasMatch("\r"));
  assertTrue(re.hasMatch("\u2028"));
  assertTrue(re.hasMatch("\u2029"));

  // DotAll '.' behavior (unicode).
  re = new RegExp(r"^.$", unicode: true, dotAll: true);
  assertTrue(re.hasMatch("a"));
  assertTrue(re.hasMatch("3"));
  assertTrue(re.hasMatch("π"));
  assertTrue(re.hasMatch("\u2027"));
  assertTrue(re.hasMatch("\u0085"));
  assertTrue(re.hasMatch("\v"));
  assertTrue(re.hasMatch("\f"));
  assertTrue(re.hasMatch("\u180E"));
  assertTrue(re.hasMatch("\u{10300}")); // Supplementary plane.
  assertTrue(re.hasMatch("\n"));
  assertTrue(re.hasMatch("\r"));
  assertTrue(re.hasMatch("\u2028"));
  assertTrue(re.hasMatch("\u2029"));
}
