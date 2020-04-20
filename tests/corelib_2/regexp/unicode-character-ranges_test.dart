// Copyright (c) 2019, the Dart project authors. All rights reserved.
// Copyright 2011 the V8 project authors. All rights reserved.
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

import 'package:expect/expect.dart';

import 'v8_regexp_utils.dart';

void execl(List<String> expectation, RegExp re, String subject) {
  shouldBe(re.firstMatch(subject), expectation);
}

void execs(List<String> expectation, String pattern, String subject) {
  final re = RegExp(pattern, unicode: true);
  shouldBe(re.firstMatch(subject), expectation);
}

void main() {
  // Character ranges.
  execs(["A"], r"[A-D]", "A");
  execs(["ABCD"], r"[A-D]+", "ZABCDEF");

  execs(["\u{12345}"], r"[\u1234-\u{12345}]", "\u{12345}");
  execs(null, r"[^\u1234-\u{12345}]", "\u{12345}");

  execs(["\u{1234}"], r"[\u1234-\u{12345}]", "\u{1234}");
  execs(null, r"[^\u1234-\u{12345}]", "\u{1234}");

  execs(null, r"[\u1234-\u{12345}]", "\u{1233}");
  execs(["\u{1233}"], r"[^\u1234-\u{12345}]", "\u{1233}");

  execs(["\u{12346}"], r"[^\u1234-\u{12345}]", "\u{12346}");
  execs(null, r"[\u1234-\u{12345}]", "\u{12346}");

  execs(["\u{12342}"], r"[\u{12340}-\u{12345}]", "\u{12342}");
  execs(["\u{12342}"], r"[\ud808\udf40-\ud808\udf45]", "\u{12342}");
  execs(null, r"[^\u{12340}-\u{12345}]", "\u{12342}");
  execs(null, r"[^\ud808\udf40-\ud808\udf45]", "\u{12342}");

  execs(["\u{ffff}"], r"[\u{ff80}-\u{12345}]", "\u{ffff}");
  execs(["\u{ffff}"], r"[\u{ff80}-\ud808\udf45]", "\u{ffff}");
  execs(null, r"[^\u{ff80}-\u{12345}]", "\u{ffff}");
  execs(null, r"[^\u{ff80}-\ud808\udf45]", "\u{ffff}");

  // Lone surrogate
  execs(["\udc00"], r"[^\u{ff80}-\u{12345}]", "\uff99\u{dc00}A");
  execs(["\udc01"], r"[\u0100-\u{10ffff}]", "A\udc01");
  execs(["\udc03"], r"[\udc01-\udc03]", "\ud801\udc02\udc03");
  execs(["\ud801"], r"[\ud801-\ud803]", "\ud802\udc01\ud801");

  // Paired surrogate.
  execs(null, r"[^\u{ff80}-\u{12345}]", "\u{d800}\u{dc00}");
  execs(["\ud800\udc00"], r"[\u{ff80}-\u{12345}]", "\u{d800}\u{dc00}");
  execs(["foo\u{10e6d}bar"], r"foo\ud803\ude6dbar", "foo\u{10e6d}bar");

  // Lone surrogates
  execs(["\ud801\ud801"], r"\ud801+", "\ud801\udc01\ud801\ud801");
  execs(["\udc01\udc01"], r"\udc01+", "\ud801\ud801\udc01\udc01\udc01");

  execs(["\udc02\udc03A"], r"\W\WA", "\ud801\udc01A\udc02\udc03A");
  execs(["\ud801\ud802"], r"\ud801.", "\ud801\udc01\ud801\ud802");
  execs(["\udc02\udc03A"], r"[\ud800-\udfff][\ud800-\udfff]A",
      "\ud801\udc01A\udc02\udc03A");

  // Character classes
  execs(null, r"\w", "\ud801\udc01");
  execl(["\ud801"], RegExp(r"[^\w]"), "\ud801\udc01");
  execs(["\ud801\udc01"], r"[^\w]", "\ud801\udc01");
  execl(["\ud801"], RegExp(r"\W"), "\ud801\udc01");
  execs(["\ud801\udc01"], r"\W", "\ud801\udc01");

  execs(["\ud800X"], r".X", "\ud800XaX");
  execs(["aX"], r".(?<!\ud800)X", "\ud800XaX");
  execs(["aX"], r".(?<![\ud800-\ud900])X", "\ud800XaX");

  execs(null, r"[]", "\u1234");
  execs(["0abc"], r"[^]abc", "0abc");
  execs(["\u1234abc"], r"[^]abc", "\u1234abc");
  execs(["\u{12345}abc"], r"[^]abc", "\u{12345}abc");

  execs(null, r"[\u{0}-\u{1F444}]", "\ud83d\udfff");

  // Backward matches of lone surrogates.
  execs(["B", "\ud803A"], r"(?<=([\ud800-\ud900]A))B",
      "\ud801\udc00AB\udc00AB\ud802\ud803AB");
  execs(["B", "\udc00A"], r"(?<=([\ud800-\u{10300}]A))B",
      "\ud801\udc00AB\udc00AB\ud802\ud803AB");
  execs(["B", "\udc11A"], r"(?<=([\udc00-\udd00]A))B",
      "\ud801\udc00AB\udc11AB\ud802\ud803AB");
  execs(["X", "\ud800C"], r"(?<=(\ud800\w))X",
      "\ud800\udc00AX\udc11BX\ud800\ud800CX");
  execs(["C", "\ud800\ud800"], r"(?<=(\ud800.))\w",
      "\ud800\udc00AX\udc11BX\ud800\ud800CX");
  execs(["X", "\udc01C"], r"(?<=(\udc01\w))X",
      "\ud800\udc01AX\udc11BX\udc01\udc01CX");
  execs(["C", "\udc01\udc01"], r"(?<=(\udc01.)).",
      "\ud800\udc01AX\udc11BX\udc01\udc01CX");

  const L = "\ud800";
  const T = "\udc00";
  const X = "X";

  // Test string contains only match.
  void testw(bool expect, String src, String subject) {
    var re = RegExp(r"^" + src + r"$", unicode: true);
    assertEquals(expect, re.hasMatch(subject));
  }

  // Test string starts with match.
  void tests(bool expect, String src, String subject) {
    var re = RegExp(r"^" + src, unicode: true);
    assertEquals(expect, re.hasMatch(subject));
  }

  testw(true, X, X);
  testw(true, L, L);
  testw(true, T, T);
  testw(true, L + T, L + T);
  testw(true, T + L, T + L);
  testw(false, T, L + T);
  testw(false, L, L + T);
  testw(true, r".(?<=" + L + r")", L);
  testw(true, r".(?<=" + T + r")", T);
  testw(true, r".(?<=" + L + T + r")", L + T);
  testw(true, r".(?<=" + L + T + r")", L + T);
  tests(true, r".(?<=" + T + r")", T + L);
  tests(false, r".(?<=" + L + r")", L + T);
  tests(false, r".(?<=" + T + r")", L + T);
  tests(true, r"..(?<=" + T + r")", T + T + L);
  tests(true, r"..(?<=" + T + r")", X + T + L);
  tests(true, r"...(?<=" + L + r")", X + T + L);
  tests(false, r"...(?<=" + T + r")", X + L + T);
  tests(true, r"..(?<=" + L + T + r")", X + L + T);
  tests(true, r"..(?<=" + L + T + r"(?<=" + L + T + r"))", X + L + T);
  tests(false, r"..(?<=" + L + r"(" + T + r"))", X + L + T);
  tests(false, r".*" + L, X + L + T);
  tests(true, r".*" + L, X + L + L + T);
  tests(false, r".*" + L, X + L + T + L + T);
  tests(false, r".*" + T, X + L + T + L + T);
  tests(true, r".*" + T, X + L + T + T + L + T);
}
