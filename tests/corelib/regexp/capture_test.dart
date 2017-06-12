// Copyright (c) 2014, the Dart project authors. All rights reserved.
// Copyright 2009 the V8 project authors. All rights reserved.
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
import 'package:expect/expect.dart';

void main() {
  // Tests from http://blog.stevenlevithan.com/archives/npcg-javascript

  assertEquals(true, new RegExp(r"(x)?\1y").hasMatch("y"));
  shouldBe(new RegExp(r"(x)?\1y").firstMatch("y"), ["y", null]);
  shouldBe(new RegExp(r"(x)?y").firstMatch("y"), ["y", null]);
  shouldBe(firstMatch("y", new RegExp(r"(x)?\1y")), ["y", null]);
  shouldBe(firstMatch("y", new RegExp(r"(x)?y")), ["y", null]);
  shouldBe(firstMatch("y", new RegExp(r"(x)?\1y")), ["y", null]);
  Expect.listEquals(["", ""], "y".split(new RegExp(r"(x)?\1y")));
  Expect.listEquals(["", ""], "y".split(new RegExp(r"(x)?y")));
  assertEquals(0, "y".indexOf(new RegExp(r"(x)?\1y")));
  assertEquals("z", "y".replaceAll(new RegExp(r"(x)?\1y"), "z"));

  // See https://bugzilla.mozilla.org/show_bug.cgi?id=476146
  shouldBe(new RegExp(r"^(b+|a){1,2}?bc").firstMatch("bbc"), ["bbc", "b"]);
  shouldBe(
      new RegExp(r"((\3|b)\2(a)){2,}").firstMatch("bbaababbabaaaaabbaaaabba"),
      ["bbaa", "a", "", "a"]);

  // From crbug.com/128821 - don't hang:
  firstMatch(
      "",
      new RegExp(
          r"((a|i|A|I|u|o|U|O)(s|c|b|c|d|f|g|h|j|k|l|m|n|p|q|r|s|t|v|w|x|y|z|B|C|D|F|G|H|J|K|L|M|N|P|Q|R|S|T|V|W|X|Y|Z)*) de\/da([.,!?\s]|$)"));
}
