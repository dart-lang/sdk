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
  dynamic oneMatch(re) {
    assertEquals("acd", "abcd".replaceAll(re, ""));
  }

  oneMatch(new RegExp(r"b"));
  oneMatch(new RegExp(r"b"));

  assertEquals("acdacd", "abcdabcd".replaceAll(new RegExp(r"b"), ""));

  dynamic captureMatch(re) {
    var match = firstMatch("abcd", re);
    assertEquals("b", match.group(1));
    assertEquals("c", match.group(2));
  }

  captureMatch(new RegExp(r"(b)(c)"));
  captureMatch(new RegExp(r"(b)(c)"));

  // A test that initially does a zero width match, but later does a non-zero
  // width match.
  var a = "foo bar baz".replaceAll(new RegExp(r"^|bar"), "");
  assertEquals("foo  baz", a);

  a = "foo bar baz".replaceAll(new RegExp(r"^|bar"), "*");
  assertEquals("*foo * baz", a);

  // We test FilterASCII using regexps that will backtrack forever.  Since
  // a regexp with a non-ASCII character in it can never match an ASCII
  // string we can test that the relevant node is removed by verifying that
  // there is no hang.
  dynamic NoHang(re) {
    firstMatch("This is an ASCII string that could take forever", re);
  }

  NoHang(new RegExp(
      r"(((.*)*)*x)Ā")); // Continuation after loop is filtered, so is loop.
  NoHang(new RegExp(r"(((.*)*)*Ā)foo")); // Body of loop filtered.
  NoHang(new RegExp(
      r"Ā(((.*)*)*x)")); // Everything after a filtered character is filtered.
  NoHang(new RegExp(
      r"(((.*)*)*x)Ā")); // Everything before a filtered character is filtered.
  NoHang(new RegExp(
      r"[ćăĀ](((.*)*)*x)")); // Everything after a filtered class is filtered.
  NoHang(new RegExp(
      r"(((.*)*)*x)[ćăĀ]")); // Everything before a filtered class is filtered.
  NoHang(new RegExp(r"[^\x00-\xff](((.*)*)*x)")); // After negated class.
  NoHang(new RegExp(r"(((.*)*)*x)[^\x00-\xff]")); // Before negated class.
  NoHang(new RegExp(r"(?!(((.*)*)*x)Ā)foo")); // Negative lookahead is filtered.
  NoHang(new RegExp(
      r"(?!(((.*)*)*x))Ā")); // Continuation branch of negative lookahead.
  NoHang(new RegExp(r"(?=(((.*)*)*x)Ā)foo")); // Positive lookahead is filtered.
  NoHang(new RegExp(
      r"(?=(((.*)*)*x))Ā")); // Continuation branch of positive lookahead.
  NoHang(new RegExp(
      r"(?=Ā)(((.*)*)*x)")); // Positive lookahead also prunes continuation.
  NoHang(new RegExp(
      r"(æ|ø|Ā)(((.*)*)*x)")); // All branches of alternation are filtered.
  NoHang(new RegExp(r"(a|b|(((.*)*)*x))Ā")); // 1 out of 3 branches pruned.
  NoHang(new RegExp(
      r"(a|(((.*)*)*x)ă|(((.*)*)*x)Ā)")); // 2 out of 3 branches pruned.

  var s = "Don't prune based on a repetition of length 0";
  assertEquals(null, firstMatch(s, new RegExp(r"å{1,1}prune")));
  assertEquals("prune", (firstMatch(s, new RegExp(r"å{0,0}prune"))[0]));

  // Some very deep regexps where FilterASCII gives up in order not to make the
  // stack overflow.
  var regex6 = new RegExp(r"a*\u0100*\w");
  var input0 = "a";
  regex6.firstMatch(input0);

  var re = "\u0100*\\w";

  for (var i = 0; i < 200; i++) re = "a*" + re;

  var regex7 = new RegExp(re);
  regex7.firstMatch(input0);

  var regex8 = new RegExp(re, caseSensitive: false);
  regex8.firstMatch(input0);

  re = "[\u0100]*\\w";
  for (var i = 0; i < 200; i++) re = "a*" + re;

  var regex9 = new RegExp(re);
  regex9.firstMatch(input0);

  var regex10 = new RegExp(re, caseSensitive: false);
  regex10.firstMatch(input0);

  var regex11 = new RegExp(r"^(?:[^\u0000-\u0080]|[0-9a-z?,.!&\s#()])+$",
      caseSensitive: false);
  regex11.firstMatch(input0);

  var regex12 = new RegExp(
      r"u(\xf0{8}?\D*?|( ? !)$h??(|)*?(||)+?\6((?:\W\B|--\d-*-|)?$){0, }?|^Y( ? !1)\d+)+a");
  regex12.firstMatch("");
}
