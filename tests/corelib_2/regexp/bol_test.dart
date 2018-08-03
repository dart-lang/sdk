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
  description('Test for beginning of line (BOL or ^) matching</a>');

  var s = "abc123def456xyzabc789abc999";
  shouldBeNull(firstMatch(s, new RegExp(r"^notHere")));
  shouldBe(firstMatch(s, new RegExp(r"^abc")), ["abc"]);
  shouldBe(firstMatch(s, new RegExp(r"(^|X)abc")), ["abc", ""]);
  shouldBe(firstMatch(s, new RegExp(r"^longer|123")), ["123"]);
  shouldBe(firstMatch(s, new RegExp(r"(^abc|c)123")), ["abc123", "abc"]);
  shouldBe(firstMatch(s, new RegExp(r"(c|^abc)123")), ["abc123", "abc"]);
  shouldBe(firstMatch(s, new RegExp(r"(^ab|abc)123")), ["abc123", "abc"]);
  shouldBe(firstMatch(s, new RegExp(r"(bc|^abc)([0-9]*)a")),
      ["bc789a", "bc", "789"]);
  shouldBeNull(new RegExp(r"(?:(Y)X)|(X)").firstMatch("abc"));
  shouldBeNull(new RegExp(r"(?:(?:^|Y)X)|(X)").firstMatch("abc"));
  shouldBeNull(new RegExp(r"(?:(?:^|Y)X)|(X)").firstMatch("abcd"));
  shouldBe(new RegExp(r"(?:(?:^|Y)X)|(X)").firstMatch("Xabcd"), ["X", null]);
  shouldBe(new RegExp(r"(?:(?:^|Y)X)|(X)").firstMatch("aXbcd"), ["X", "X"]);
  shouldBe(new RegExp(r"(?:(?:^|Y)X)|(X)").firstMatch("abXcd"), ["X", "X"]);
  shouldBe(new RegExp(r"(?:(?:^|Y)X)|(X)").firstMatch("abcXd"), ["X", "X"]);
  shouldBe(new RegExp(r"(?:(?:^|Y)X)|(X)").firstMatch("abcdX"), ["X", "X"]);
  shouldBe(new RegExp(r"(?:(?:^|Y)X)|(X)").firstMatch("YXabcd"), ["YX", null]);
  shouldBe(new RegExp(r"(?:(?:^|Y)X)|(X)").firstMatch("aYXbcd"), ["YX", null]);
  shouldBe(new RegExp(r"(?:(?:^|Y)X)|(X)").firstMatch("abYXcd"), ["YX", null]);
  shouldBe(new RegExp(r"(?:(?:^|Y)X)|(X)").firstMatch("abcYXd"), ["YX", null]);
  shouldBe(new RegExp(r"(?:(?:^|Y)X)|(X)").firstMatch("abcdYX"), ["YX", null]);
}
