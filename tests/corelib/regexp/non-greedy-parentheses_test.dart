// Copyright (c) 2014, the Dart project authors. All rights reserved.
// Copyright 2013 the V8 project authors. All rights reserved.
// Copyright (C) 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1.  Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
// 2.  Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in the
//     documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import 'v8_regexp_utils.dart';
import 'package:expect/expect.dart';

void main() {
  description(
    'Test for regression against <a href="https://bugs.webkit.org/show_bug.cgi?id=39289">Wrong result in case of non-iterative matching of subpatterns in non-greedy cases in YARR Interpreter</a>',
  );

  shouldBe(firstMatch("a", new RegExp(r"(a)??")), ["", null]);
  shouldBe(firstMatch("b", new RegExp(r"(a)??")), ["", null]);
  shouldBe(firstMatch("ab", new RegExp(r"(a)??b")), ["ab", "a"]);
  shouldBe(firstMatch("aaab", new RegExp(r"(a+)??b")), ["aaab", "aaa"]);
  shouldBe(firstMatch("abbc", new RegExp(r"(a)??(b+)??c")), [
    "abbc",
    "a",
    "bb",
  ]);
  shouldBe(firstMatch("ac", new RegExp(r"(a)??(b)??c")), ["ac", "a", null]);
  shouldBe(firstMatch("abc", new RegExp(r"(a(b)??)??c")), ["abc", "ab", "b"]);
  shouldBe(firstMatch("ac", new RegExp(r"(a(b)??)??c")), ["ac", "a", null]);
}
