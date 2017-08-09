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
      "This page tests the regex examples from the ECMA-262 specification.");

  var regex01 = new RegExp(r"a|ab");
  shouldBe(regex01.firstMatch("abc"), ["a"]);

  var regex02 = new RegExp(r"((a)|(ab))((c)|(bc))");
  shouldBe(
      regex02.firstMatch("abc"), ["abc", "a", "a", null, "bc", null, "bc"]);

  var regex03 = new RegExp(r"a[a-z]{2,4}");
  shouldBe(regex03.firstMatch("abcdefghi"), ["abcde"]);

  var regex04 = new RegExp(r"a[a-z]{2,4}?");
  shouldBe(regex04.firstMatch("abcdefghi"), ["abc"]);

  var regex05 = new RegExp(r"(aa|aabaac|ba|b|c)*");
  shouldBe(regex05.firstMatch("aabaac"), ["aaba", "ba"]);

  var regex06 = new RegExp(r"^(a+)\1*,\1+$");
  Expect.equals(
      "aaaaaaaaaa,aaaaaaaaaaaaaaa".replaceAllMapped(regex06, (m) => m.group(1)),
      "aaaaa");

  var regex07 = new RegExp(r"(z)((a+)?(b+)?(c))*");
  shouldBe(regex07.firstMatch("zaacbbbcac"),
      ["zaacbbbcac", "z", "ac", "a", null, "c"]);

  var regex08 = new RegExp(r"(a*)*");
  shouldBe(regex08.firstMatch("b"), ["", null]);

  var regex09 = new RegExp(r"(a*)b\1+");
  shouldBe(regex09.firstMatch("baaaac"), ["b", ""]);

  var regex10 = new RegExp(r"(?=(a+))");
  shouldBe(regex10.firstMatch("baaabac"), ["", "aaa"]);

  var regex11 = new RegExp(r"(?=(a+))a*b\1");
  shouldBe(regex11.firstMatch("baaabac"), ["aba", "a"]);

  var regex12 = new RegExp(r"(.*?)a(?!(a+)b\2c)\2(.*)");
  shouldBe(regex12.firstMatch("baaabaac"), ["baaabaac", "ba", null, "abaac"]);
}
