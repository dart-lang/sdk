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
      "A chunk of our port of PCRE's test suite, adapted to be more applicable to JavaScript.");

  var regex0 = new RegExp(r"a.b");
  var input0 = "acb";
  var results = ["acb"];
  shouldBe(regex0.firstMatch(input0), results);
  var input1 = "a\x7fb";
  results = ["a\u007fb"];
  shouldBe(regex0.firstMatch(input1), results);
  var input2 = "a\u0100b";
  results = ["a\u0100b"];
  shouldBe(regex0.firstMatch(input2), results);
  // Failers
  var input3 = "a\nb";
  results = null;
  shouldBe(regex0.firstMatch(input3), results);

  var regex1 = new RegExp(r"a(.{3})b");
  input0 = "a\u4000xyb";
  results = ["a\u4000xyb", "\u4000xy"];
  shouldBe(regex1.firstMatch(input0), results);
  input1 = "a\u4000\x7fyb";
  results = ["a\u4000\u007fyb", "\u4000\u007fy"];
  shouldBe(regex1.firstMatch(input1), results);
  input2 = "a\u4000\u0100yb";
  results = ["a\u4000\u0100yb", "\u4000\u0100y"];
  shouldBe(regex1.firstMatch(input2), results);
  // Failers
  input3 = "a\u4000b";
  results = null;
  shouldBe(regex1.firstMatch(input3), results);
  var input4 = "ac\ncb";
  results = null;
  shouldBe(regex1.firstMatch(input4), results);

  var regex2 = new RegExp(r"a(.*?)(.)");
  input0 = "a\xc0\x88b";
  results = ["a\xc0", "", "\xc0"];
  shouldBe(regex2.firstMatch(input0), results);

  var regex3 = new RegExp(r"a(.*?)(.)");
  input0 = "a\u0100b";
  results = ["a\u0100", "", "\u0100"];
  shouldBe(regex3.firstMatch(input0), results);

  var regex4 = new RegExp(r"a(.*)(.)");
  input0 = "a\xc0\x88b";
  results = ["a\xc0\x88b", "\xc0\x88", "b"];
  shouldBe(regex4.firstMatch(input0), results);

  var regex5 = new RegExp(r"a(.*)(.)");
  input0 = "a\u0100b";
  results = ["a\u0100b", "\u0100", "b"];
  shouldBe(regex5.firstMatch(input0), results);

  var regex6 = new RegExp(r"a(.)(.)");
  input0 = "a\xc0\x92bcd";
  results = ["a\xc0\x92", "\xc0", "\x92"];
  shouldBe(regex6.firstMatch(input0), results);

  var regex7 = new RegExp(r"a(.)(.)");
  input0 = "a\u0240bcd";
  results = ["a\u0240b", "\u0240", "b"];
  shouldBe(regex7.firstMatch(input0), results);

  var regex8 = new RegExp(r"a(.?)(.)");
  input0 = "a\xc0\x92bcd";
  results = ["a\xc0\x92", "\xc0", "\x92"];
  shouldBe(regex8.firstMatch(input0), results);

  var regex9 = new RegExp(r"a(.?)(.)");
  input0 = "a\u0240bcd";
  results = ["a\u0240b", "\u0240", "b"];
  shouldBe(regex9.firstMatch(input0), results);

  var regex10 = new RegExp(r"a(.??)(.)");
  input0 = "a\xc0\x92bcd";
  results = ["a\xc0", "", "\xc0"];
  shouldBe(regex10.firstMatch(input0), results);

  var regex11 = new RegExp(r"a(.??)(.)");
  input0 = "a\u0240bcd";
  results = ["a\u0240", "", "\u0240"];
  shouldBe(regex11.firstMatch(input0), results);

  var regex12 = new RegExp(r"a(.{3})b");
  input0 = "a\u1234xyb";
  results = ["a\u1234xyb", "\u1234xy"];
  shouldBe(regex12.firstMatch(input0), results);
  input1 = "a\u1234\u4321yb";
  results = ["a\u1234\u4321yb", "\u1234\u4321y"];
  shouldBe(regex12.firstMatch(input1), results);
  input2 = "a\u1234\u4321\u3412b";
  results = ["a\u1234\u4321\u3412b", "\u1234\u4321\u3412"];
  shouldBe(regex12.firstMatch(input2), results);
  // Failers
  input3 = "a\u1234b";
  results = null;
  shouldBe(regex12.firstMatch(input3), results);
  input4 = "ac\ncb";
  results = null;
  shouldBe(regex12.firstMatch(input4), results);

  var regex13 = new RegExp(r"a(.{3,})b");
  input0 = "a\u1234xyb";
  results = ["a\u1234xyb", "\u1234xy"];
  shouldBe(regex13.firstMatch(input0), results);
  input1 = "a\u1234\u4321yb";
  results = ["a\u1234\u4321yb", "\u1234\u4321y"];
  shouldBe(regex13.firstMatch(input1), results);
  input2 = "a\u1234\u4321\u3412b";
  results = ["a\u1234\u4321\u3412b", "\u1234\u4321\u3412"];
  shouldBe(regex13.firstMatch(input2), results);
  input3 = "axxxxbcdefghijb";
  results = ["axxxxbcdefghijb", "xxxxbcdefghij"];
  shouldBe(regex13.firstMatch(input3), results);
  input4 = "a\u1234\u4321\u3412\u3421b";
  results = ["a\u1234\u4321\u3412\u3421b", "\u1234\u4321\u3412\u3421"];
  shouldBe(regex13.firstMatch(input4), results);
  // Failers
  var input5 = "a\u1234b";
  results = null;
  shouldBe(regex13.firstMatch(input5), results);

  var regex14 = new RegExp(r"a(.{3,}?)b");
  input0 = "a\u1234xyb";
  results = ["a\u1234xyb", "\u1234xy"];
  shouldBe(regex14.firstMatch(input0), results);
  input1 = "a\u1234\u4321yb";
  results = ["a\u1234\u4321yb", "\u1234\u4321y"];
  shouldBe(regex14.firstMatch(input1), results);
  input2 = "a\u1234\u4321\u3412b";
  results = ["a\u1234\u4321\u3412b", "\u1234\u4321\u3412"];
  shouldBe(regex14.firstMatch(input2), results);
  input3 = "axxxxbcdefghijb";
  results = ["axxxxb", "xxxx"];
  shouldBe(regex14.firstMatch(input3), results);
  input4 = "a\u1234\u4321\u3412\u3421b";
  results = ["a\u1234\u4321\u3412\u3421b", "\u1234\u4321\u3412\u3421"];
  shouldBe(regex14.firstMatch(input4), results);
  // Failers
  input5 = "a\u1234b";
  results = null;
  shouldBe(regex14.firstMatch(input5), results);

  var regex15 = new RegExp(r"a(.{3,5})b");
  input0 = "a\u1234xyb";
  results = ["a\u1234xyb", "\u1234xy"];
  shouldBe(regex15.firstMatch(input0), results);
  input1 = "a\u1234\u4321yb";
  results = ["a\u1234\u4321yb", "\u1234\u4321y"];
  shouldBe(regex15.firstMatch(input1), results);
  input2 = "a\u1234\u4321\u3412b";
  results = ["a\u1234\u4321\u3412b", "\u1234\u4321\u3412"];
  shouldBe(regex15.firstMatch(input2), results);
  input3 = "axxxxbcdefghijb";
  results = ["axxxxb", "xxxx"];
  shouldBe(regex15.firstMatch(input3), results);
  input4 = "a\u1234\u4321\u3412\u3421b";
  results = ["a\u1234\u4321\u3412\u3421b", "\u1234\u4321\u3412\u3421"];
  shouldBe(regex15.firstMatch(input4), results);
  input5 = "axbxxbcdefghijb";
  results = ["axbxxb", "xbxx"];
  shouldBe(regex15.firstMatch(input5), results);
  var input6 = "axxxxxbcdefghijb";
  results = ["axxxxxb", "xxxxx"];
  shouldBe(regex15.firstMatch(input6), results);
  // Failers
  var input7 = "a\u1234b";
  results = null;
  shouldBe(regex15.firstMatch(input7), results);
  var input8 = "axxxxxxbcdefghijb";
  results = null;
  shouldBe(regex15.firstMatch(input8), results);

  var regex16 = new RegExp(r"a(.{3,5}?)b");
  input0 = "a\u1234xyb";
  results = ["a\u1234xyb", "\u1234xy"];
  shouldBe(regex16.firstMatch(input0), results);
  input1 = "a\u1234\u4321yb";
  results = ["a\u1234\u4321yb", "\u1234\u4321y"];
  shouldBe(regex16.firstMatch(input1), results);
  input2 = "a\u1234\u4321\u3412b";
  results = ["a\u1234\u4321\u3412b", "\u1234\u4321\u3412"];
  shouldBe(regex16.firstMatch(input2), results);
  input3 = "axxxxbcdefghijb";
  results = ["axxxxb", "xxxx"];
  shouldBe(regex16.firstMatch(input3), results);
  input4 = "a\u1234\u4321\u3412\u3421b";
  results = ["a\u1234\u4321\u3412\u3421b", "\u1234\u4321\u3412\u3421"];
  shouldBe(regex16.firstMatch(input4), results);
  input5 = "axbxxbcdefghijb";
  results = ["axbxxb", "xbxx"];
  shouldBe(regex16.firstMatch(input5), results);
  input6 = "axxxxxbcdefghijb";
  results = ["axxxxxb", "xxxxx"];
  shouldBe(regex16.firstMatch(input6), results);
  // Failers
  input7 = "a\u1234b";
  results = null;
  shouldBe(regex16.firstMatch(input7), results);
  input8 = "axxxxxxbcdefghijb";
  results = null;
  shouldBe(regex16.firstMatch(input8), results);

  var regex17 = new RegExp(r"^[a\u00c0]");
  // Failers
  input0 = "\u0100";
  results = null;
  shouldBe(regex17.firstMatch(input0), results);

  var regex21 = new RegExp(r"(?:\u0100){3}b");
  input0 = "\u0100\u0100\u0100b";
  results = ["\u0100\u0100\u0100b"];
  shouldBe(regex21.firstMatch(input0), results);
  // Failers
  input1 = "\u0100\u0100b";
  results = null;
  shouldBe(regex21.firstMatch(input1), results);

  var regex22 = new RegExp(r"\u00ab");
  input0 = "\u00ab";
  results = ["\u00ab"];
  shouldBe(regex22.firstMatch(input0), results);
  input1 = "\xc2\xab";
  results = ["\u00ab"];
  shouldBe(regex22.firstMatch(input1), results);
  // Failers
  input2 = "\x00{ab}";
  results = null;
  shouldBe(regex22.firstMatch(input2), results);

  var regex30 = new RegExp(r"^[^a]{2}");
  input0 = "\u0100bc";
  results = ["\u0100b"];
  shouldBe(regex30.firstMatch(input0), results);

  var regex31 = new RegExp(r"^[^a]{2,}");
  input0 = "\u0100bcAa";
  results = ["\u0100bcA"];
  shouldBe(regex31.firstMatch(input0), results);

  var regex32 = new RegExp(r"^[^a]{2,}?");
  input0 = "\u0100bca";
  results = ["\u0100b"];
  shouldBe(regex32.firstMatch(input0), results);

  var regex33 = new RegExp(r"^[^a]{2}", caseSensitive: false);
  input0 = "\u0100bc";
  results = ["\u0100b"];
  shouldBe(regex33.firstMatch(input0), results);

  var regex34 = new RegExp(r"^[^a]{2,}", caseSensitive: false);
  input0 = "\u0100bcAa";
  results = ["\u0100bc"];
  shouldBe(regex34.firstMatch(input0), results);

  var regex35 = new RegExp(r"^[^a]{2,}?", caseSensitive: false);
  input0 = "\u0100bca";
  results = ["\u0100b"];
  shouldBe(regex35.firstMatch(input0), results);

  var regex36 = new RegExp(r"\u0100{0,0}");
  input0 = "abcd";
  results = [""];
  shouldBe(regex36.firstMatch(input0), results);

  var regex37 = new RegExp(r"\u0100?");
  input0 = "abcd";
  results = [""];
  shouldBe(regex37.firstMatch(input0), results);
  input1 = "\u0100\u0100";
  results = ["\u0100"];
  shouldBe(regex37.firstMatch(input1), results);

  var regex38 = new RegExp(r"\u0100{0,3}");
  input0 = "\u0100\u0100";
  results = ["\u0100\u0100"];
  shouldBe(regex38.firstMatch(input0), results);
  input1 = "\u0100\u0100\u0100\u0100";
  results = ["\u0100\u0100\u0100"];
  shouldBe(regex38.firstMatch(input1), results);

  var regex39 = new RegExp(r"\u0100*");
  input0 = "abce";
  results = [""];
  shouldBe(regex39.firstMatch(input0), results);
  input1 = "\u0100\u0100\u0100\u0100";
  results = ["\u0100\u0100\u0100\u0100"];
  shouldBe(regex39.firstMatch(input1), results);

  var regex40 = new RegExp(r"\u0100{1,1}");
  input0 = "abcd\u0100\u0100\u0100\u0100";
  results = ["\u0100"];
  shouldBe(regex40.firstMatch(input0), results);

  var regex41 = new RegExp(r"\u0100{1,3}");
  input0 = "abcd\u0100\u0100\u0100\u0100";
  results = ["\u0100\u0100\u0100"];
  shouldBe(regex41.firstMatch(input0), results);

  var regex42 = new RegExp(r"\u0100+");
  input0 = "abcd\u0100\u0100\u0100\u0100";
  results = ["\u0100\u0100\u0100\u0100"];
  shouldBe(regex42.firstMatch(input0), results);

  var regex43 = new RegExp(r"\u0100{3}");
  input0 = "abcd\u0100\u0100\u0100XX";
  results = ["\u0100\u0100\u0100"];
  shouldBe(regex43.firstMatch(input0), results);

  var regex44 = new RegExp(r"\u0100{3,5}");
  input0 = "abcd\u0100\u0100\u0100\u0100\u0100\u0100\u0100XX";
  results = ["\u0100\u0100\u0100\u0100\u0100"];
  shouldBe(regex44.firstMatch(input0), results);

  var regex45 = new RegExp(r"\u0100{3,}");
  input0 = "abcd\u0100\u0100\u0100\u0100\u0100\u0100\u0100XX";
  results = ["\u0100\u0100\u0100\u0100\u0100\u0100\u0100"];
  shouldBe(regex45.firstMatch(input0), results);

  var regex47 = new RegExp(r"\D*");
  input0 =
      "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
  results = [
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  ];
  shouldBe(regex47.firstMatch(input0), results);

  var regex48 = new RegExp(r"\D*");
  input0 =
      "\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100";
  results = [
    "\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100\u0100"
  ];
  shouldBe(regex48.firstMatch(input0), results);

  var regex49 = new RegExp(r"\D");
  input0 = "1X2";
  results = ["X"];
  shouldBe(regex49.firstMatch(input0), results);
  input1 = "1\u01002";
  results = ["\u0100"];
  shouldBe(regex49.firstMatch(input1), results);

  var regex50 = new RegExp(r">\S");
  input0 = "> >X Y";
  results = [">X"];
  shouldBe(regex50.firstMatch(input0), results);
  input1 = "> >\u0100 Y";
  results = [">\u0100"];
  shouldBe(regex50.firstMatch(input1), results);

  var regex51 = new RegExp(r"\d");
  input0 = "\u01003";
  results = ["3"];
  shouldBe(regex51.firstMatch(input0), results);

  var regex52 = new RegExp(r"\s");
  input0 = "\u0100 X";
  results = [" "];
  shouldBe(regex52.firstMatch(input0), results);

  var regex53 = new RegExp(r"\D+");
  input0 = "12abcd34";
  results = ["abcd"];
  shouldBe(regex53.firstMatch(input0), results);
  // Failers
  input1 = "1234";
  results = null;
  shouldBe(regex53.firstMatch(input1), results);

  var regex54 = new RegExp(r"\D{2,3}");
  input0 = "12abcd34";
  results = ["abc"];
  shouldBe(regex54.firstMatch(input0), results);
  input1 = "12ab34";
  results = ["ab"];
  shouldBe(regex54.firstMatch(input1), results);
  // Failers
  input2 = "1234";
  results = null;
  shouldBe(regex54.firstMatch(input2), results);
  input3 = "12a34";
  results = null;
  shouldBe(regex54.firstMatch(input3), results);

  var regex55 = new RegExp(r"\D{2,3}?");
  input0 = "12abcd34";
  results = ["ab"];
  shouldBe(regex55.firstMatch(input0), results);
  input1 = "12ab34";
  results = ["ab"];
  shouldBe(regex55.firstMatch(input1), results);
  // Failers
  input2 = "1234";
  results = null;
  shouldBe(regex55.firstMatch(input2), results);
  input3 = "12a34";
  results = null;
  shouldBe(regex55.firstMatch(input3), results);

  var regex56 = new RegExp(r"\d+");
  input0 = "12abcd34";
  results = ["12"];
  shouldBe(regex56.firstMatch(input0), results);

  var regex57 = new RegExp(r"\d{2,3}");
  input0 = "12abcd34";
  results = ["12"];
  shouldBe(regex57.firstMatch(input0), results);
  input1 = "1234abcd";
  results = ["123"];
  shouldBe(regex57.firstMatch(input1), results);
  // Failers
  input2 = "1.4";
  results = null;
  shouldBe(regex57.firstMatch(input2), results);

  var regex58 = new RegExp(r"\d{2,3}?");
  input0 = "12abcd34";
  results = ["12"];
  shouldBe(regex58.firstMatch(input0), results);
  input1 = "1234abcd";
  results = ["12"];
  shouldBe(regex58.firstMatch(input1), results);
  // Failers
  input2 = "1.4";
  results = null;
  shouldBe(regex58.firstMatch(input2), results);

  var regex59 = new RegExp(r"\S+");
  input0 = "12abcd34";
  results = ["12abcd34"];
  shouldBe(regex59.firstMatch(input0), results);
  // Failers
  input1 = "    ";
  results = null;
  shouldBe(regex59.firstMatch(input1), results);

  var regex60 = new RegExp(r"\S{2,3}");
  input0 = "12abcd34";
  results = ["12a"];
  shouldBe(regex60.firstMatch(input0), results);
  input1 = "1234abcd";
  results = ["123"];
  shouldBe(regex60.firstMatch(input1), results);
  // Failers
  input2 = "    ";
  results = null;
  shouldBe(regex60.firstMatch(input2), results);

  var regex61 = new RegExp(r"\S{2,3}?");
  input0 = "12abcd34";
  results = ["12"];
  shouldBe(regex61.firstMatch(input0), results);
  input1 = "1234abcd";
  results = ["12"];
  shouldBe(regex61.firstMatch(input1), results);
  // Failers
  input2 = "    ";
  results = null;
  shouldBe(regex61.firstMatch(input2), results);

  var regex62 = new RegExp(r">\s+<");
  input0 = "12>      <34";
  results = [">      <"];
  shouldBe(regex62.firstMatch(input0), results);

  var regex63 = new RegExp(r">\s{2,3}<");
  input0 = "ab>  <cd";
  results = [">  <"];
  shouldBe(regex63.firstMatch(input0), results);
  input1 = "ab>   <ce";
  results = [">   <"];
  shouldBe(regex63.firstMatch(input1), results);
  // Failers
  input2 = "ab>    <cd";
  results = null;
  shouldBe(regex63.firstMatch(input2), results);

  var regex64 = new RegExp(r">\s{2,3}?<");
  input0 = "ab>  <cd";
  results = [">  <"];
  shouldBe(regex64.firstMatch(input0), results);
  input1 = "ab>   <ce";
  results = [">   <"];
  shouldBe(regex64.firstMatch(input1), results);
  // Failers
  input2 = "ab>    <cd";
  results = null;
  shouldBe(regex64.firstMatch(input2), results);

  var regex65 = new RegExp(r"\w+");
  input0 = "12      34";
  results = ["12"];
  shouldBe(regex65.firstMatch(input0), results);
  // Failers
  input1 = "+++=*!";
  results = null;
  shouldBe(regex65.firstMatch(input1), results);

  var regex66 = new RegExp(r"\w{2,3}");
  input0 = "ab  cd";
  results = ["ab"];
  shouldBe(regex66.firstMatch(input0), results);
  input1 = "abcd ce";
  results = ["abc"];
  shouldBe(regex66.firstMatch(input1), results);
  // Failers
  input2 = "a.b.c";
  results = null;
  shouldBe(regex66.firstMatch(input2), results);

  var regex67 = new RegExp(r"\w{2,3}?");
  input0 = "ab  cd";
  results = ["ab"];
  shouldBe(regex67.firstMatch(input0), results);
  input1 = "abcd ce";
  results = ["ab"];
  shouldBe(regex67.firstMatch(input1), results);
  // Failers
  input2 = "a.b.c";
  results = null;
  shouldBe(regex67.firstMatch(input2), results);

  var regex68 = new RegExp(r"\W+");
  input0 = "12====34";
  results = ["===="];
  shouldBe(regex68.firstMatch(input0), results);
  // Failers
  input1 = "abcd";
  results = null;
  shouldBe(regex68.firstMatch(input1), results);

  var regex69 = new RegExp(r"\W{2,3}");
  input0 = "ab====cd";
  results = ["==="];
  shouldBe(regex69.firstMatch(input0), results);
  input1 = "ab==cd";
  results = ["=="];
  shouldBe(regex69.firstMatch(input1), results);
  // Failers
  input2 = "a.b.c";
  results = null;
  shouldBe(regex69.firstMatch(input2), results);

  var regex70 = new RegExp(r"\W{2,3}?");
  input0 = "ab====cd";
  results = ["=="];
  shouldBe(regex70.firstMatch(input0), results);
  input1 = "ab==cd";
  results = ["=="];
  shouldBe(regex70.firstMatch(input1), results);
  // Failers
  input2 = "a.b.c";
  results = null;
  shouldBe(regex70.firstMatch(input2), results);

  var regex71 = new RegExp(r"[\u0100]");
  input0 = "\u0100";
  results = ["\u0100"];
  shouldBe(regex71.firstMatch(input0), results);
  input1 = "Z\u0100";
  results = ["\u0100"];
  shouldBe(regex71.firstMatch(input1), results);
  input2 = "\u0100Z";
  results = ["\u0100"];
  shouldBe(regex71.firstMatch(input2), results);

  var regex72 = new RegExp(r"[Z\u0100]");
  input0 = "Z\u0100";
  results = ["Z"];
  shouldBe(regex72.firstMatch(input0), results);
  input1 = "\u0100";
  results = ["\u0100"];
  shouldBe(regex72.firstMatch(input1), results);
  input2 = "\u0100Z";
  results = ["\u0100"];
  shouldBe(regex72.firstMatch(input2), results);

  var regex73 = new RegExp(r"[\u0100\u0200]");
  input0 = "ab\u0100cd";
  results = ["\u0100"];
  shouldBe(regex73.firstMatch(input0), results);
  input1 = "ab\u0200cd";
  results = ["\u0200"];
  shouldBe(regex73.firstMatch(input1), results);

  var regex74 = new RegExp(r"[\u0100-\u0200]");
  input0 = "ab\u0100cd";
  results = ["\u0100"];
  shouldBe(regex74.firstMatch(input0), results);
  input1 = "ab\u0200cd";
  results = ["\u0200"];
  shouldBe(regex74.firstMatch(input1), results);
  input2 = "ab\u0111cd";
  results = ["\u0111"];
  shouldBe(regex74.firstMatch(input2), results);

  var regex75 = new RegExp(r"[z-\u0200]");
  input0 = "ab\u0100cd";
  results = ["\u0100"];
  shouldBe(regex75.firstMatch(input0), results);
  input1 = "ab\u0200cd";
  results = ["\u0200"];
  shouldBe(regex75.firstMatch(input1), results);
  input2 = "ab\u0111cd";
  results = ["\u0111"];
  shouldBe(regex75.firstMatch(input2), results);
  input3 = "abzcd";
  results = ["z"];
  shouldBe(regex75.firstMatch(input3), results);
  input4 = "ab|cd";
  results = ["|"];
  shouldBe(regex75.firstMatch(input4), results);

  var regex76 = new RegExp(r"[Q\u0100\u0200]");
  input0 = "ab\u0100cd";
  results = ["\u0100"];
  shouldBe(regex76.firstMatch(input0), results);
  input1 = "ab\u0200cd";
  results = ["\u0200"];
  shouldBe(regex76.firstMatch(input1), results);
  input2 = "Q?";
  results = ["Q"];
  shouldBe(regex76.firstMatch(input2), results);

  var regex77 = new RegExp(r"[Q\u0100-\u0200]");
  input0 = "ab\u0100cd";
  results = ["\u0100"];
  shouldBe(regex77.firstMatch(input0), results);
  input1 = "ab\u0200cd";
  results = ["\u0200"];
  shouldBe(regex77.firstMatch(input1), results);
  input2 = "ab\u0111cd";
  results = ["\u0111"];
  shouldBe(regex77.firstMatch(input2), results);
  input3 = "Q?";
  results = ["Q"];
  shouldBe(regex77.firstMatch(input3), results);

  var regex78 = new RegExp(r"[Qz-\u0200]");
  input0 = "ab\u0100cd";
  results = ["\u0100"];
  shouldBe(regex78.firstMatch(input0), results);
  input1 = "ab\u0200cd";
  results = ["\u0200"];
  shouldBe(regex78.firstMatch(input1), results);
  input2 = "ab\u0111cd";
  results = ["\u0111"];
  shouldBe(regex78.firstMatch(input2), results);
  input3 = "abzcd";
  results = ["z"];
  shouldBe(regex78.firstMatch(input3), results);
  input4 = "ab|cd";
  results = ["|"];
  shouldBe(regex78.firstMatch(input4), results);
  input5 = "Q?";
  results = ["Q"];
  shouldBe(regex78.firstMatch(input5), results);

  var regex79 = new RegExp(r"[\u0100\u0200]{1,3}");
  input0 = "ab\u0100cd";
  results = ["\u0100"];
  shouldBe(regex79.firstMatch(input0), results);
  input1 = "ab\u0200cd";
  results = ["\u0200"];
  shouldBe(regex79.firstMatch(input1), results);
  input2 = "ab\u0200\u0100\u0200\u0100cd";
  results = ["\u0200\u0100\u0200"];
  shouldBe(regex79.firstMatch(input2), results);

  var regex80 = new RegExp(r"[\u0100\u0200]{1,3}?");
  input0 = "ab\u0100cd";
  results = ["\u0100"];
  shouldBe(regex80.firstMatch(input0), results);
  input1 = "ab\u0200cd";
  results = ["\u0200"];
  shouldBe(regex80.firstMatch(input1), results);
  input2 = "ab\u0200\u0100\u0200\u0100cd";
  results = ["\u0200"];
  shouldBe(regex80.firstMatch(input2), results);

  var regex81 = new RegExp(r"[Q\u0100\u0200]{1,3}");
  input0 = "ab\u0100cd";
  results = ["\u0100"];
  shouldBe(regex81.firstMatch(input0), results);
  input1 = "ab\u0200cd";
  results = ["\u0200"];
  shouldBe(regex81.firstMatch(input1), results);
  input2 = "ab\u0200\u0100\u0200\u0100cd";
  results = ["\u0200\u0100\u0200"];
  shouldBe(regex81.firstMatch(input2), results);

  var regex82 = new RegExp(r"[Q\u0100\u0200]{1,3}?");
  input0 = "ab\u0100cd";
  results = ["\u0100"];
  shouldBe(regex82.firstMatch(input0), results);
  input1 = "ab\u0200cd";
  results = ["\u0200"];
  shouldBe(regex82.firstMatch(input1), results);
  input2 = "ab\u0200\u0100\u0200\u0100cd";
  results = ["\u0200"];
  shouldBe(regex82.firstMatch(input2), results);

  var regex86 = new RegExp(r"[^\u0100\u0200]X");
  input0 = "AX";
  results = ["AX"];
  shouldBe(regex86.firstMatch(input0), results);
  input1 = "\u0150X";
  results = ["\u0150X"];
  shouldBe(regex86.firstMatch(input1), results);
  input2 = "\u0500X";
  results = ["\u0500X"];
  shouldBe(regex86.firstMatch(input2), results);
  // Failers
  input3 = "\u0100X";
  results = null;
  shouldBe(regex86.firstMatch(input3), results);
  input4 = "\u0200X";
  results = null;
  shouldBe(regex86.firstMatch(input4), results);

  var regex87 = new RegExp(r"[^Q\u0100\u0200]X");
  input0 = "AX";
  results = ["AX"];
  shouldBe(regex87.firstMatch(input0), results);
  input1 = "\u0150X";
  results = ["\u0150X"];
  shouldBe(regex87.firstMatch(input1), results);
  input2 = "\u0500X";
  results = ["\u0500X"];
  shouldBe(regex87.firstMatch(input2), results);
  // Failers
  input3 = "\u0100X";
  results = null;
  shouldBe(regex87.firstMatch(input3), results);
  input4 = "\u0200X";
  results = null;
  shouldBe(regex87.firstMatch(input4), results);
  input5 = "QX";
  results = null;
  shouldBe(regex87.firstMatch(input5), results);

  var regex88 = new RegExp(r"[^\u0100-\u0200]X");
  input0 = "AX";
  results = ["AX"];
  shouldBe(regex88.firstMatch(input0), results);
  input1 = "\u0500X";
  results = ["\u0500X"];
  shouldBe(regex88.firstMatch(input1), results);
  // Failers
  input2 = "\u0100X";
  results = null;
  shouldBe(regex88.firstMatch(input2), results);
  input3 = "\u0150X";
  results = null;
  shouldBe(regex88.firstMatch(input3), results);
  input4 = "\u0200X";
  results = null;
  shouldBe(regex88.firstMatch(input4), results);

  var regex91 = new RegExp(r"[z-\u0100]", caseSensitive: false);
  input0 = "z";
  results = ["z"];
  shouldBe(regex91.firstMatch(input0), results);
  input1 = "Z";
  results = ["Z"];
  shouldBe(regex91.firstMatch(input1), results);
  input2 = "\u0100";
  results = ["\u0100"];
  shouldBe(regex91.firstMatch(input2), results);
  // Failers
  input3 = "\u0102";
  results = null;
  shouldBe(regex91.firstMatch(input3), results);
  input4 = "y";
  results = null;
  shouldBe(regex91.firstMatch(input4), results);

  var regex92 = new RegExp(r"[\xFF]");
  input0 = ">\xff<";
  results = ["\xff"];
  shouldBe(regex92.firstMatch(input0), results);

  var regex93 = new RegExp(r"[\xff]");
  input0 = ">\u00ff<";
  results = ["\u00ff"];
  shouldBe(regex93.firstMatch(input0), results);

  var regex94 = new RegExp(r"[^\xFF]");
  input0 = "XYZ";
  results = ["X"];
  shouldBe(regex94.firstMatch(input0), results);

  var regex95 = new RegExp(r"[^\xff]");
  input0 = "XYZ";
  results = ["X"];
  shouldBe(regex95.firstMatch(input0), results);
  input1 = "\u0123";
  results = ["\u0123"];
  shouldBe(regex95.firstMatch(input1), results);

  var regex96 = new RegExp(r"^[ac]*b");
  input0 = "xb";
  results = null;
  shouldBe(regex96.firstMatch(input0), results);

  var regex97 = new RegExp(r"^[ac\u0100]*b");
  input0 = "xb";
  results = null;
  shouldBe(regex97.firstMatch(input0), results);

  var regex98 = new RegExp(r"^[^x]*b", caseSensitive: false);
  input0 = "xb";
  results = null;
  shouldBe(regex98.firstMatch(input0), results);

  var regex99 = new RegExp(r"^[^x]*b");
  input0 = "xb";
  results = null;
  shouldBe(regex99.firstMatch(input0), results);

  var regex100 = new RegExp(r"^\d*b");
  input0 = "xb";
  results = null;
  shouldBe(regex100.firstMatch(input0), results);

  var regex102 = new RegExp(r"^\u0085$", caseSensitive: false);
  input0 = "\u0085";
  results = ["\u0085"];
  shouldBe(regex102.firstMatch(input0), results);

  var regex103 = new RegExp(r"^\xe1\x88\xb4");
  input0 = "\xe1\x88\xb4";
  results = ["\xe1\x88\xb4"];
  shouldBe(regex103.firstMatch(input0), results);

  var regex104 = new RegExp(r"^\xe1\x88\xb4");
  input0 = "\xe1\x88\xb4";
  results = ["\xe1\x88\xb4"];
  shouldBe(regex104.firstMatch(input0), results);

  var regex105 = new RegExp(r"(.{1,5})");
  input0 = "abcdefg";
  results = ["abcde", "abcde"];
  shouldBe(regex105.firstMatch(input0), results);
  input1 = "ab";
  results = ["ab", "ab"];
  shouldBe(regex105.firstMatch(input1), results);

  var regex106 = new RegExp(r"a*\u0100*\w");
  input0 = "a";
  results = ["a"];
  shouldBe(regex106.firstMatch(input0), results);

  var regex107 = new RegExp(r"[\S\s]*");
  input0 = "abc\n\r\u0442\u0435\u0441\u0442xyz";
  results = ["abc\u000a\u000d\u0442\u0435\u0441\u0442xyz"];
  shouldBe(regex107.firstMatch(input0), results);

  var regexGlobal0 = new RegExp(r"[^a]+");
  input0 = "bcd";
  results = ["bcd"];
  shouldBe(firstMatch(input0, regexGlobal0), results);
  input1 = "\u0100aY\u0256Z";
  results = ["\u0100", "Y\u0256Z"];
  Expect.listEquals(
      regexGlobal0.allMatches(input1).map((m) => m.group(0)).toList(), results);

  var regexGlobal1 = new RegExp(r"\S\S");
  input0 = "A\u00a3BC";
  results = ["A\u00a3", "BC"];
  Expect.listEquals(allStringMatches(input0, regexGlobal1), results);

  var regexGlobal2 = new RegExp(r"\S{2}");
  input0 = "A\u00a3BC";
  results = ["A\u00a3", "BC"];
  Expect.listEquals(allStringMatches(input0, regexGlobal2), results);

  var regexGlobal3 = new RegExp(r"\W\W");
  input0 = "+\u00a3==";
  results = ["+\u00a3", "=="];
  Expect.listEquals(allStringMatches(input0, regexGlobal3), results);

  var regexGlobal4 = new RegExp(r"\W{2}");
  input0 = "+\u00a3==";
  results = ["+\u00a3", "=="];
  Expect.listEquals(allStringMatches(input0, regexGlobal4), results);

  var regexGlobal5 = new RegExp(r"\S");
  input0 = "\u0442\u0435\u0441\u0442";
  results = ["\u0442", "\u0435", "\u0441", "\u0442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal5), results);

  var regexGlobal6 = new RegExp(r"[\S]");
  input0 = "\u0442\u0435\u0441\u0442";
  results = ["\u0442", "\u0435", "\u0441", "\u0442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal6), results);

  var regexGlobal7 = new RegExp(r"\D");
  input0 = "\u0442\u0435\u0441\u0442";
  results = ["\u0442", "\u0435", "\u0441", "\u0442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal7), results);

  var regexGlobal8 = new RegExp(r"[\D]");
  input0 = "\u0442\u0435\u0441\u0442";
  results = ["\u0442", "\u0435", "\u0441", "\u0442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal8), results);

  var regexGlobal9 = new RegExp(r"\W");
  input0 = "\u2442\u2435\u2441\u2442";
  results = ["\u2442", "\u2435", "\u2441", "\u2442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal9), results);

  var regexGlobal10 = new RegExp(r"[\W]");
  input0 = "\u2442\u2435\u2441\u2442";
  results = ["\u2442", "\u2435", "\u2441", "\u2442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal10), results);

  var regexGlobal11 = new RegExp(r"[\u041f\S]");
  input0 = "\u0442\u0435\u0441\u0442";
  results = ["\u0442", "\u0435", "\u0441", "\u0442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal11), results);

  var regexGlobal12 = new RegExp(r".[^\S].");
  input0 = "abc def\u0442\u0443xyz\npqr";
  results = ["c d", "z\u000ap"];
  Expect.listEquals(allStringMatches(input0, regexGlobal12), results);

  var regexGlobal13 = new RegExp(r".[^\S\n].");
  input0 = "abc def\u0442\u0443xyz\npqr";
  results = ["c d"];
  Expect.listEquals(allStringMatches(input0, regexGlobal13), results);

  var regexGlobal14 = new RegExp(r"[\W]");
  input0 = "+\u2442";
  results = ["+", "\u2442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal14), results);

  var regexGlobal15 = new RegExp(r"[^a-zA-Z]");
  input0 = "+\u2442";
  results = ["+", "\u2442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal15), results);

  var regexGlobal16 = new RegExp(r"[^a-zA-Z]");
  input0 = "A\u0442";
  results = ["\u0442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal16), results);

  var regexGlobal17 = new RegExp(r"[\S]");
  input0 = "A\u0442";
  results = ["A", "\u0442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal17), results);

  var regexGlobal19 = new RegExp(r"[\D]");
  input0 = "A\u0442";
  results = ["A", "\u0442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal19), results);

  var regexGlobal21 = new RegExp(r"[^a-z]");
  input0 = "A\u0422";
  results = ["A", "\u0422"];
  Expect.listEquals(allStringMatches(input0, regexGlobal21), results);

  var regexGlobal24 = new RegExp(r"[\S]");
  input0 = "A\u0442";
  results = ["A", "\u0442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal24), results);

  var regexGlobal25 = new RegExp(r"[^A-Z]");
  input0 = "a\u0442";
  results = ["a", "\u0442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal25), results);

  var regexGlobal26 = new RegExp(r"[\W]");
  input0 = "+\u2442";
  results = ["+", "\u2442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal26), results);

  var regexGlobal27 = new RegExp(r"[\D]");
  input0 = "M\u0442";
  results = ["M", "\u0442"];
  Expect.listEquals(allStringMatches(input0, regexGlobal27), results);

  var regexGlobal28 = new RegExp(r"[^a]+", caseSensitive: false);
  input0 = "bcd";
  results = ["bcd"];
  Expect.listEquals(allStringMatches(input0, regexGlobal28), results);
  input1 = "\u0100aY\u0256Z";
  results = ["\u0100", "Y\u0256Z"];
  Expect.listEquals(allStringMatches(input1, regexGlobal28), results);

  var regexGlobal29 = new RegExp(r"(a|)");
  input0 = "catac";
  results = ["", "a", "", "a", "", ""];
  Expect.listEquals(allStringMatches(input0, regexGlobal29), results);
  input1 = "a\u0256a";
  results = ["a", "", "a", ""];
  Expect.listEquals(allStringMatches(input1, regexGlobal29), results);
}
