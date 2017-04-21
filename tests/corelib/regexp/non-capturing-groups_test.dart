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
      'Test for behavior of non-capturing groups, as described in <a href="http://blog.stevenlevithan.com/archives/npcg-javascript">' +
          'a blog post by Steven Levithan</a> and <a href="http://bugs.webkit.org/show_bug.cgi?id=14931">bug 14931</a>.');

  shouldBeTrue(new RegExp(r"(x)?\1y").hasMatch("y"));
  shouldBe(new RegExp(r"(x)?\1y").firstMatch("y"), ["y", null]);
  shouldBe(new RegExp(r"(x)?y").firstMatch("y"), ["y", null]);
  shouldBe(firstMatch("y", new RegExp(r"(x)?\1y")), ["y", null]);
  shouldBe(firstMatch("y", new RegExp(r"(x)?y")), ["y", null]);
  shouldBe(firstMatch("y", new RegExp(r"(x)?\1y")), ["y", null]);
  Expect.listEquals("y".split(new RegExp(r"(x)?\1y")), ["", ""]);
  Expect.listEquals("y".split(new RegExp(r"(x)?y")), ["", ""]);
  assertEquals("y".indexOf(new RegExp(r"(x)?\1y")), 0);
  assertEquals("y".replaceAll(new RegExp(r"(x)?\1y"), "z"), "z");
  assertEquals(
      "y".replaceAllMapped(new RegExp(r"(x)?y"), (m) => m.group(1)), "null");
  assertEquals(
      "y".replaceAllMapped(new RegExp(r"(x)?\1y"), (m) => m.group(1)), "null");
  assertEquals(
      "y".replaceAllMapped(new RegExp(r"(x)?y"), (m) => m.group(1)), "null");
}
