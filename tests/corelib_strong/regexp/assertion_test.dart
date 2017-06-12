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
  description("This page tests handling of parenthetical assertions.");

  var regex1 = new RegExp(r"(x)(?=\1)x");
  shouldBe(regex1.firstMatch('xx'), ['xx', 'x']);

  var regex2 = new RegExp(r"(.*?)a(?!(a+)b\2c)\2(.*)");
  shouldBe(regex2.firstMatch('baaabaac'), ['baaabaac', 'ba', null, 'abaac']);

  var regex3 = new RegExp(r"(?=(a+?))(\1ab)");
  shouldBe(regex3.firstMatch('aaab'), ['aab', 'a', 'aab']);

  var regex4 = new RegExp(r"(?=(a+?))(\1ab)");
  shouldBe(regex4.firstMatch('aaab'), ['aab', 'a', 'aab']);

  var regex5 = new RegExp(r"^P([1-6])(?=\1)([1-6])$");
  shouldBe(regex5.firstMatch('P11'), ['P11', '1', '1']);

  var regex6 = new RegExp(r"(([a-c])b*?\2)*");
  shouldBe(regex6.firstMatch('ababbbcbc'), ['ababb', 'bb', 'b']);

  var regex7 = new RegExp(r"(x)(?=x)x");
  shouldBe(regex7.firstMatch('xx'), ['xx', 'x']);

  var regex8 = new RegExp(r"(x)(\1)");
  shouldBe(regex8.firstMatch('xx'), ['xx', 'x', 'x']);

  var regex9 = new RegExp(r"(x)(?=\1)x");
  shouldBeNull(regex9.firstMatch('xy'));

  var regex10 = new RegExp(r"(x)(?=x)x");
  shouldBeNull(regex10.firstMatch('xy'));

  var regex11 = new RegExp(r"(x)(\1)");
  shouldBeNull(regex11.firstMatch('xy'));

  var regex12 = new RegExp(r"(x)(?=\1)x");
  shouldBeNull(regex12.firstMatch('x'));
  shouldBe(regex12.firstMatch('xx'), ['xx', 'x']);
  shouldBe(regex12.firstMatch('xxy'), ['xx', 'x']);

  var regex13 = new RegExp(r"(x)zzz(?=\1)x");
  shouldBe(regex13.firstMatch('xzzzx'), ['xzzzx', 'x']);
  shouldBe(regex13.firstMatch('xzzzxy'), ['xzzzx', 'x']);

  var regex14 = new RegExp(r"(a)\1(?=(b*c))bc");
  shouldBe(regex14.firstMatch('aabc'), ['aabc', 'a', 'bc']);
  shouldBe(regex14.firstMatch('aabcx'), ['aabc', 'a', 'bc']);

  var regex15 = new RegExp(r"(a)a(?=(b*c))bc");
  shouldBe(regex15.firstMatch('aabc'), ['aabc', 'a', 'bc']);
  shouldBe(regex15.firstMatch('aabcx'), ['aabc', 'a', 'bc']);

  var regex16 = new RegExp(r"a(?=(b*c))bc");
  shouldBeNull(regex16.firstMatch('ab'));
  shouldBe(regex16.firstMatch('abc'), ['abc', 'bc']);

  var regex17 = new RegExp(r"(?=((?:ab)*))a");
  shouldBe(regex17.firstMatch('ab'), ['a', 'ab']);
  shouldBe(regex17.firstMatch('abc'), ['a', 'ab']);

  var regex18 = new RegExp(r"(?=((?:xx)*))x");
  shouldBe(regex18.firstMatch('x'), ['x', '']);
  shouldBe(regex18.firstMatch('xx'), ['x', 'xx']);
  shouldBe(regex18.firstMatch('xxx'), ['x', 'xx']);

  var regex19 = new RegExp(r"(?=((xx)*))x");
  shouldBe(regex19.firstMatch('x'), ['x', '', null]);
  shouldBe(regex19.firstMatch('xx'), ['x', 'xx', 'xx']);
  shouldBe(regex19.firstMatch('xxx'), ['x', 'xx', 'xx']);

  var regex20 = new RegExp(r"(?=(xx))+x");
  shouldBeNull(regex20.firstMatch('x'));
  shouldBe(regex20.firstMatch('xx'), ['x', 'xx']);
  shouldBe(regex20.firstMatch('xxx'), ['x', 'xx']);

  var regex21 = new RegExp(r"(?=a+b)aab");
  shouldBe(regex21.firstMatch('aab'), ['aab']);

  var regex22 = new RegExp(
      r"(?!(u|m{0,}g+)u{1,}|2{2,}!1%n|(?!K|(?=y)|(?=ip))+?)(?=(?=(((?:7))*?)*?))p",
      multiLine: true);
  shouldBeNull(regex22.firstMatch('55up'));

  var regex23 = new RegExp(r"(?=(a)b|c?)()*d");
  shouldBeNull(regex23.firstMatch('ax'));

  var regex24 = new RegExp(r"(?=a|b?)c");
  shouldBeNull(regex24.firstMatch('x'));
}
