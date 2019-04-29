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

  t(RegExp(r"\p{Script=Common}+", unicode: true), ".");
  f(RegExp(r"\p{Script=Common}+", unicode: true),
      "supercalifragilisticexpialidocious");

  t(RegExp(r"\p{Script=Han}+", unicode: true), "话说天下大势，分久必合，合久必分");
  t(RegExp(r"\p{Script=Hani}+", unicode: true), "吾庄后有一桃园，花开正盛");
  f(RegExp(r"\p{Script=Han}+", unicode: true), "おはようございます");
  f(RegExp(r"\p{Script=Hani}+", unicode: true),
      "Something is rotten in the state of Denmark");

  t(RegExp(r"\p{Script=Latin}+", unicode: true),
      "Wie froh bin ich, daß ich weg bin!");
  t(RegExp(r"\p{Script=Latn}+", unicode: true),
      "It was a bright day in April, and the clocks were striking thirteen");
  f(RegExp(r"\p{Script=Latin}+", unicode: true), "奔腾千里荡尘埃，渡水登山紫雾开");
  f(RegExp(r"\p{Script=Latn}+", unicode: true), "いただきます");

  t(RegExp(r"\p{sc=Hiragana}", unicode: true), "いただきます");
  t(RegExp(r"\p{sc=Hira}", unicode: true), "ありがとうございました");
  f(RegExp(r"\p{sc=Hiragana}", unicode: true),
      "Als Gregor Samsa eines Morgens aus unruhigen Träumen erwachte");
  f(RegExp(r"\p{sc=Hira}", unicode: true), "Call me Ishmael");

  t(RegExp(r"\p{sc=Phoenician}", unicode: true), "\u{10900}\u{1091a}");
  t(RegExp(r"\p{sc=Phnx}", unicode: true), "\u{1091f}\u{10916}");
  f(RegExp(r"\p{sc=Phoenician}", unicode: true), "Arthur est un perroquet");
  f(RegExp(r"\p{sc=Phnx}", unicode: true), "设心狠毒非良士，操卓原来一路人");

  t(RegExp(r"\p{sc=Grek}", unicode: true),
      "ἄνδρα μοι ἔννεπε, μοῦσα, πολύτροπον, ὃς μάλα πολλὰ");
  t(RegExp(r"\p{sc=Greek}", unicode: true),
      "μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος");
  f(RegExp(r"\p{sc=Greek}", unicode: true), "高贤未服英雄志，屈节偏生杰士疑");
  f(RegExp(r"\p{sc=Greek}", unicode: true),
      "Mr. Jones, of the Manor Farm, had locked the hen-houses for the night");
}
