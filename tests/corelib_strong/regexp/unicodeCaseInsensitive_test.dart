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
  shouldBeTrue(new RegExp(r"ΣΤΙΓΜΑΣ", caseSensitive: false).hasMatch("στιγμας"));
  shouldBeTrue(new RegExp(r"ΔΣΔ", caseSensitive: false).hasMatch("δςδ"));
  shouldBeTrue(new RegExp(r"ς", caseSensitive: false).hasMatch("σ"));
  shouldBeTrue(new RegExp(r"σ", caseSensitive: false).hasMatch("ς"));

  // Simple case, has no canonical equivalents
  shouldBeTrue(new RegExp(r"\u1f16", caseSensitive: false).hasMatch("\u1f16"));

  // Test the sets of USC2 code points that have more than one canonically equivalent value.
  dynamic ucs2CodePoint(x) => new String.fromCharCode(x);
  dynamic testSet(s)
  {
      for (var i in s) {
          for (var j in s) {
              shouldBeTrue(new RegExp(ucs2CodePoint(i), caseSensitive: false).hasMatch(ucs2CodePoint(j)));
              shouldBeTrue(new RegExp("[${ucs2CodePoint(i - 1)}-${ucs2CodePoint(i + 1)}]", caseSensitive: false).hasMatch(ucs2CodePoint(j)));
          }
      }
  }
  testSet([ 0x01c4, 0x01c5, 0x01c6 ]);
  testSet([ 0x01c7, 0x01c8, 0x01c9 ]);
  testSet([ 0x01ca, 0x01cb, 0x01cc ]);
  testSet([ 0x01f1, 0x01f2, 0x01f3 ]);
  testSet([ 0x0392, 0x03b2, 0x03d0 ]);
  testSet([ 0x0395, 0x03b5, 0x03f5 ]);
  testSet([ 0x0398, 0x03b8, 0x03d1 ]);
  testSet([ 0x0345, 0x0399, 0x03b9, 0x1fbe ]);
  testSet([ 0x039a, 0x03ba, 0x03f0 ]);
  testSet([ 0x00b5, 0x039c, 0x03bc ]);
  testSet([ 0x03a0, 0x03c0, 0x03d6 ]);
  testSet([ 0x03a1, 0x03c1, 0x03f1 ]);
  testSet([ 0x03a3, 0x03c2, 0x03c3 ]);
  testSet([ 0x03a6, 0x03c6, 0x03d5 ]);
  testSet([ 0x1e60, 0x1e61, 0x1e9b ]);

  // Test a couple of lo/hi pairs
  shouldBeTrue(new RegExp(r"\u03cf", caseSensitive: false).hasMatch("\u03cf"));
  shouldBeTrue(new RegExp(r"\u03d7", caseSensitive: false).hasMatch("\u03cf"));
  shouldBeTrue(new RegExp(r"\u03cf", caseSensitive: false).hasMatch("\u03d7"));
  shouldBeTrue(new RegExp(r"\u03d7", caseSensitive: false).hasMatch("\u03d7"));
  shouldBeTrue(new RegExp(r"\u1f11", caseSensitive: false).hasMatch("\u1f11"));
  shouldBeTrue(new RegExp(r"\u1f19", caseSensitive: false).hasMatch("\u1f11"));
  shouldBeTrue(new RegExp(r"\u1f11", caseSensitive: false).hasMatch("\u1f19"));
  shouldBeTrue(new RegExp(r"\u1f19", caseSensitive: false).hasMatch("\u1f19"));

  // Test an aligned alternating capitalization pair.
  shouldBeFalse(new RegExp(r"\u0489", caseSensitive: false).hasMatch("\u048a"));
  shouldBeTrue(new RegExp(r"\u048a", caseSensitive: false).hasMatch("\u048a"));
  shouldBeTrue(new RegExp(r"\u048b", caseSensitive: false).hasMatch("\u048a"));
  shouldBeFalse(new RegExp(r"\u048c", caseSensitive: false).hasMatch("\u048a"));
  shouldBeFalse(new RegExp(r"\u0489", caseSensitive: false).hasMatch("\u048b"));
  shouldBeTrue(new RegExp(r"\u048a", caseSensitive: false).hasMatch("\u048b"));
  shouldBeTrue(new RegExp(r"\u048b", caseSensitive: false).hasMatch("\u048b"));
  shouldBeFalse(new RegExp(r"\u048c", caseSensitive: false).hasMatch("\u048b"));
  shouldBeTrue(new RegExp(r"[\u0489-\u048a]", caseSensitive: false).hasMatch("\u048b"));
  shouldBeTrue(new RegExp(r"[\u048b-\u048c]", caseSensitive: false).hasMatch("\u048a"));

  // Test an unaligned alternating capitalization pair.
  shouldBeFalse(new RegExp(r"\u04c4", caseSensitive: false).hasMatch("\u04c5"));
  shouldBeTrue(new RegExp(r"\u04c5", caseSensitive: false).hasMatch("\u04c5"));
  shouldBeTrue(new RegExp(r"\u04c6", caseSensitive: false).hasMatch("\u04c5"));
  shouldBeFalse(new RegExp(r"\u04c7", caseSensitive: false).hasMatch("\u04c5"));
  shouldBeFalse(new RegExp(r"\u04c4", caseSensitive: false).hasMatch("\u04c6"));
  shouldBeTrue(new RegExp(r"\u04c5", caseSensitive: false).hasMatch("\u04c6"));
  shouldBeTrue(new RegExp(r"\u04c6", caseSensitive: false).hasMatch("\u04c6"));
  shouldBeFalse(new RegExp(r"\u04c7", caseSensitive: false).hasMatch("\u04c6"));
  shouldBeTrue(new RegExp(r"[\u04c4-\u04c5]", caseSensitive: false).hasMatch("\u04c6"));
  shouldBeTrue(new RegExp(r"[\u04c6-\u04c7]", caseSensitive: false).hasMatch("\u04c5"));

  var successfullyParsed = true;
}
