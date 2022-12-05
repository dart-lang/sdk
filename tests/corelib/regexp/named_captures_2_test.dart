// Copyright (c) 2022, the Dart project authors. All rights reserved.
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

import 'v8_regexp_utils.dart';

// These test cases really belong in `named_captures_test` but they've been
// broken out because they currently fail on all web backends.
void main() {
  assertThrows(() => RegExp(r"(?<$𐒤>a)"));
  assertThrows(() => RegExp("(?<a\uD801\uDCA4>.)"));
  assertThrows(() => RegExp(r"(?<a\uD801\uDCA4>.)"));
  assertThrows(() => RegExp("(?<a\uD801>.)"));
  assertThrows(() => RegExp(r"(?<a\uD801>.)"));
  assertThrows(() => RegExp("(?<a\uDCA4>.)"));
  assertThrows(() => RegExp(r"(?<a\uDCA4>.)"));
  assertThrows(() => RegExp("(?<a\u{104A4}>.)"));
  assertThrows(() => RegExp(r"(?<a\u{104A4}>.)"));
  assertThrows(() => RegExp("(?<a\u{10FFFF}>.)"));
  assertThrows(() => RegExp(r"(?<a\u{10FFFF}>.)"));
  assertThrows(() => RegExp(r"(?<a\\u{110000}>.)"));
}
