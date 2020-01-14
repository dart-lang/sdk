// Copyright (c) 2019, the Dart project authors. All rights reserved.
// Copyright 2016 the V8 project authors. All rights reserved.
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

import 'package:expect/expect.dart';

import 'v8_regexp_utils.dart';

void main() {
  void t(RegExp re, String s) {
    assertTrue(re.hasMatch(s));
  }

  void f(RegExp re, String s) {
    assertFalse(re.hasMatch(s));
  }

  assertThrows(() => RegExp("\\p{Hiragana}", unicode: true));
  assertThrows(() => RegExp("\\p{Bidi_Class}", unicode: true));
  assertThrows(() => RegExp("\\p{Bidi_C=False}", unicode: true));
  assertThrows(() => RegExp("\\P{Bidi_Control=Y}", unicode: true));
  assertThrows(() => RegExp("\\p{AHex=Yes}", unicode: true));

  assertThrows(() => RegExp("\\p{Composition_Exclusion}", unicode: true));
  assertThrows(() => RegExp("\\p{CE}", unicode: true));
  assertThrows(() => RegExp("\\p{Full_Composition_Exclusion}", unicode: true));
  assertThrows(() => RegExp("\\p{Comp_Ex}", unicode: true));
  assertThrows(() => RegExp("\\p{Grapheme_Link}", unicode: true));
  assertThrows(() => RegExp("\\p{Gr_Link}", unicode: true));
  assertThrows(() => RegExp("\\p{Hyphen}", unicode: true));
  assertThrows(() => RegExp("\\p{NFD_Inert}", unicode: true));
  assertThrows(() => RegExp("\\p{NFDK_Inert}", unicode: true));
  assertThrows(() => RegExp("\\p{NFC_Inert}", unicode: true));
  assertThrows(() => RegExp("\\p{NFKC_Inert}", unicode: true));
  assertThrows(() => RegExp("\\p{Segment_Starter}", unicode: true));

  t(RegExp(r"\p{Alphabetic}", unicode: true), "æ");
  f(RegExp(r"\p{Alpha}", unicode: true), "1");

  t(RegExp(r"\p{ASCII_Hex_Digit}", unicode: true), "f");
  f(RegExp(r"\p{AHex}", unicode: true), "g");

  t(RegExp(r"\p{Bidi_Control}", unicode: true), "\u200e");
  f(RegExp(r"\p{Bidi_C}", unicode: true), "g");

  t(RegExp(r"\p{Bidi_Mirrored}", unicode: true), "(");
  f(RegExp(r"\p{Bidi_M}", unicode: true), "-");

  t(RegExp(r"\p{Case_Ignorable}", unicode: true), "\u02b0");
  f(RegExp(r"\p{CI}", unicode: true), "a");

  t(RegExp(r"\p{Changes_When_Casefolded}", unicode: true), "B");
  f(RegExp(r"\p{CWCF}", unicode: true), "1");

  t(RegExp(r"\p{Changes_When_Casemapped}", unicode: true), "b");
  f(RegExp(r"\p{CWCM}", unicode: true), "1");

  t(RegExp(r"\p{Changes_When_Lowercased}", unicode: true), "B");
  f(RegExp(r"\p{CWL}", unicode: true), "1");

  t(RegExp(r"\p{Changes_When_Titlecased}", unicode: true), "b");
  f(RegExp(r"\p{CWT}", unicode: true), "1");

  t(RegExp(r"\p{Changes_When_Uppercased}", unicode: true), "b");
  f(RegExp(r"\p{CWU}", unicode: true), "1");

  t(RegExp(r"\p{Dash}", unicode: true), "-");
  f(RegExp(r"\p{Dash}", unicode: true), "1");

  t(RegExp(r"\p{Default_Ignorable_Code_Point}", unicode: true), "\u00ad");
  f(RegExp(r"\p{DI}", unicode: true), "1");

  t(RegExp(r"\p{Deprecated}", unicode: true), "\u17a3");
  f(RegExp(r"\p{Dep}", unicode: true), "1");

  t(RegExp(r"\p{Diacritic}", unicode: true), "\u0301");
  f(RegExp(r"\p{Dia}", unicode: true), "1");

  t(RegExp(r"\p{Emoji}", unicode: true), "\u2603");
  f(RegExp(r"\p{Emoji}", unicode: true), "x");

  t(RegExp(r"\p{Emoji_Component}", unicode: true), "\u{1F1E6}");
  f(RegExp(r"\p{Emoji_Component}", unicode: true), "x");

  t(RegExp(r"\p{Emoji_Modifier_Base}", unicode: true), "\u{1F6CC}");
  f(RegExp(r"\p{Emoji_Modifier_Base}", unicode: true), "x");

  t(RegExp(r"\p{Emoji_Modifier}", unicode: true), "\u{1F3FE}");
  f(RegExp(r"\p{Emoji_Modifier}", unicode: true), "x");

  t(RegExp(r"\p{Emoji_Presentation}", unicode: true), "\u{1F308}");
  f(RegExp(r"\p{Emoji_Presentation}", unicode: true), "x");

  t(RegExp(r"\p{Extender}", unicode: true), "\u3005");
  f(RegExp(r"\p{Ext}", unicode: true), "x");

  t(RegExp(r"\p{Grapheme_Base}", unicode: true), " ");
  f(RegExp(r"\p{Gr_Base}", unicode: true), "\u0010");

  t(RegExp(r"\p{Grapheme_Extend}", unicode: true), "\u0300");
  f(RegExp(r"\p{Gr_Ext}", unicode: true), "x");

  t(RegExp(r"\p{Hex_Digit}", unicode: true), "a");
  f(RegExp(r"\p{Hex}", unicode: true), "g");

  t(RegExp(r"\p{ID_Continue}", unicode: true), "1");
  f(RegExp(r"\p{IDC}", unicode: true), ".");

  t(RegExp(r"\p{ID_Start}", unicode: true), "a");
  f(RegExp(r"\p{IDS}", unicode: true), "1");

  t(RegExp(r"\p{Ideographic}", unicode: true), "漢");
  f(RegExp(r"\p{Ideo}", unicode: true), "H");

  t(RegExp(r"\p{IDS_Binary_Operator}", unicode: true), "\u2FF0");
  f(RegExp(r"\p{IDSB}", unicode: true), "a");

  t(RegExp(r"\p{IDS_Trinary_Operator}", unicode: true), "\u2FF2");
  f(RegExp(r"\p{IDST}", unicode: true), "a");

  t(RegExp(r"\p{Join_Control}", unicode: true), "\u200c");
  f(RegExp(r"\p{Join_C}", unicode: true), "a");

  t(RegExp(r"\p{Logical_Order_Exception}", unicode: true), "\u0e40");
  f(RegExp(r"\p{LOE}", unicode: true), "a");

  t(RegExp(r"\p{Lowercase}", unicode: true), "a");
  f(RegExp(r"\p{Lower}", unicode: true), "A");

  t(RegExp(r"\p{Math}", unicode: true), "=");
  f(RegExp(r"\p{Math}", unicode: true), "A");

  t(RegExp(r"\p{Noncharacter_Code_Point}", unicode: true), "\uFDD0");
  f(RegExp(r"\p{NChar}", unicode: true), "A");

  t(RegExp(r"\p{Pattern_Syntax}", unicode: true), "\u0021");
  f(RegExp(r"\p{NChar}", unicode: true), "A");

  t(RegExp(r"\p{Pattern_White_Space}", unicode: true), "\u0009");
  f(RegExp(r"\p{Pat_Syn}", unicode: true), "A");

  t(RegExp(r"\p{Quotation_Mark}", unicode: true), "'");
  f(RegExp(r"\p{QMark}", unicode: true), "A");

  t(RegExp(r"\p{Radical}", unicode: true), "\u2FAD");
  f(RegExp(r"\p{Radical}", unicode: true), "A");

  t(RegExp(r"\p{Regional_Indicator}", unicode: true), "\u{1F1E6}");
  f(RegExp(r"\p{Regional_Indicator}", unicode: true), "A");

  t(RegExp(r"\p{Sentence_Terminal}", unicode: true), "!");
  f(RegExp(r"\p{STerm}", unicode: true), "A");

  t(RegExp(r"\p{Soft_Dotted}", unicode: true), "i");
  f(RegExp(r"\p{SD}", unicode: true), "A");

  t(RegExp(r"\p{Terminal_Punctuation}", unicode: true), ".");
  f(RegExp(r"\p{Term}", unicode: true), "A");

  t(RegExp(r"\p{Unified_Ideograph}", unicode: true), "\u4e00");
  f(RegExp(r"\p{UIdeo}", unicode: true), "A");

  t(RegExp(r"\p{Uppercase}", unicode: true), "A");
  f(RegExp(r"\p{Upper}", unicode: true), "a");

  t(RegExp(r"\p{Variation_Selector}", unicode: true), "\uFE00");
  f(RegExp(r"\p{VS}", unicode: true), "A");

  t(RegExp(r"\p{White_Space}", unicode: true), " ");
  f(RegExp(r"\p{WSpace}", unicode: true), "A");

  t(RegExp(r"\p{XID_Continue}", unicode: true), "1");
  f(RegExp(r"\p{XIDC}", unicode: true), " ");

  t(RegExp(r"\p{XID_Start}", unicode: true), "A");
  f(RegExp(r"\p{XIDS}", unicode: true), " ");
}
