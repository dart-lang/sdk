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
      'Tests that regular expressions do not have extensions that diverge from the JavaScript specification. ' +
          'Because WebKit originally used a copy of PCRE, various non-JavaScript regular expression features were historically present. ' +
          'Also tests various related edge cases.');

  shouldBeNull(new RegExp(r"\\x{41}").firstMatch("yA1"));
  assertEquals(new RegExp(r"[\x{41}]").firstMatch("yA1").group(0), "1");
  assertEquals(new RegExp(r"\x1g").firstMatch("x1g").group(0), "x1g");
  assertEquals(new RegExp(r"[\x1g]").firstMatch("x").group(0), "x");
  assertEquals(new RegExp(r"[\x1g]").firstMatch("1").group(0), "1");
  assertEquals(
      new RegExp(r"\2147483648")
          .firstMatch(new String.fromCharCode(140) + "7483648")
          .group(0),
      new String.fromCharCode(140) + "7483648");
  assertEquals(new RegExp(r"\4294967296").firstMatch("\"94967296").group(0),
      "\"94967296");
  assertEquals(new RegExp(r"\8589934592").firstMatch("\8589934592").group(0),
      "\8589934592");
  assertEquals(
      "\nAbc\n".replaceAllMapped(new RegExp(r"(\n)[^\n]+$"), (m) => m.group(1)),
      "\nAbc\n");
  shouldBeNull(new RegExp(r"x$").firstMatch("x\n"));
  assertThrows(() => new RegExp(r"x++"));
  shouldBeNull(new RegExp(r"[]]").firstMatch("]"));

  assertEquals(new RegExp(r"\060").firstMatch("y01").group(0), "0");
  assertEquals(new RegExp(r"[\060]").firstMatch("y01").group(0), "0");
  assertEquals(new RegExp(r"\606").firstMatch("y06").group(0), "06");
  assertEquals(new RegExp(r"[\606]").firstMatch("y06").group(0), "0");
  assertEquals(new RegExp(r"[\606]").firstMatch("y6").group(0), "6");
  assertEquals(new RegExp(r"\101").firstMatch("yA1").group(0), "A");
  assertEquals(new RegExp(r"[\101]").firstMatch("yA1").group(0), "A");
  assertEquals(new RegExp(r"\1011").firstMatch("yA1").group(0), "A1");
  assertEquals(new RegExp(r"[\1011]").firstMatch("yA1").group(0), "A");
  assertEquals(new RegExp(r"[\1011]").firstMatch("y1").group(0), "1");
  assertEquals(
      new RegExp(r"\10q")
          .firstMatch("y" + new String.fromCharCode(8) + "q")
          .group(0),
      new String.fromCharCode(8) + "q");
  assertEquals(
      new RegExp(r"[\10q]")
          .firstMatch("y" + new String.fromCharCode(8) + "q")
          .group(0),
      new String.fromCharCode(8));
  assertEquals(
      new RegExp(r"\1q")
          .firstMatch("y" + new String.fromCharCode(1) + "q")
          .group(0),
      new String.fromCharCode(1) + "q");
  assertEquals(
      new RegExp(r"[\1q]")
          .firstMatch("y" + new String.fromCharCode(1) + "q")
          .group(0),
      new String.fromCharCode(1));
  assertEquals(new RegExp(r"[\1q]").firstMatch("yq").group(0), "q");
  assertEquals(new RegExp(r"\8q").firstMatch("\8q").group(0), "\8q");
  assertEquals(new RegExp(r"[\8q]").firstMatch("y8q").group(0), "8");
  assertEquals(new RegExp(r"[\8q]").firstMatch("yq").group(0), "q");
  shouldBe(new RegExp(r"(x)\1q").firstMatch("xxq"), ["xxq", "x"]);
  shouldBe(new RegExp(r"(x)[\1q]").firstMatch("xxq"), ["xq", "x"]);
  shouldBe(
      new RegExp(r"(x)[\1q]").firstMatch("xx" + new String.fromCharCode(1)),
      ["x" + new String.fromCharCode(1), "x"]);
}
