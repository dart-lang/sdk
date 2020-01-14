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
  description("This page tests handling of parentheses subexpressions.");

  var regexp1 = new RegExp(r"(a|A)(b|B)");
  shouldBe(regexp1.firstMatch('abc'), ['ab', 'a', 'b']);

  var regexp2 = new RegExp(r"(a((b)|c|d))e");
  shouldBe(regexp2.firstMatch('abacadabe'), ['abe', 'ab', 'b', 'b']);

  var regexp3 = new RegExp(r"(a(b|(c)|d))e");
  shouldBe(regexp3.firstMatch('abacadabe'), ['abe', 'ab', 'b', null]);

  var regexp4 = new RegExp(r"(a(b|c|(d)))e");
  shouldBe(regexp4.firstMatch('abacadabe'), ['abe', 'ab', 'b', null]);

  var regexp5 = new RegExp(r"(a((b)|(c)|(d)))e");
  shouldBe(
      regexp5.firstMatch('abacadabe'), ['abe', 'ab', 'b', 'b', null, null]);

  var regexp6 = new RegExp(r"(a((b)|(c)|(d)))");
  shouldBe(regexp6.firstMatch('abcde'), ['ab', 'ab', 'b', 'b', null, null]);

  var regexp7 = new RegExp(r"(a(b)??)??c");
  shouldBe(regexp7.firstMatch('abc'), ['abc', 'ab', 'b']);

  var regexp8 = new RegExp(r"(a|(e|q))(x|y)");
  shouldBe(regexp8.firstMatch('bcaddxqy'), ['qy', 'q', 'q', 'y']);

  var regexp9 = new RegExp(r"((t|b)?|a)$");
  shouldBe(
      regexp9.firstMatch('asdfjejgsdflaksdfjkeljghkjea'), ['a', 'a', null]);

  var regexp10 = new RegExp(r"(?:h|e?(?:t|b)?|a?(?:t|b)?)(?:$)");
  shouldBe(regexp10.firstMatch('asdfjejgsdflaksdfjkeljghat'), ['at']);

  var regexp11 = new RegExp(r"([Jj]ava([Ss]cript)?)\sis\s(fun\w*)");
  shouldBeNull(regexp11.firstMatch(
      'Developing with JavaScript is dangerous, do not try it without assistance'));

  var regexp12 = new RegExp(r"(?:(.+), )?(.+), (..) to (?:(.+), )?(.+), (..)");
  shouldBe(regexp12.firstMatch('Seattle, WA to Buckley, WA'), [
    'Seattle, WA to Buckley, WA',
    null,
    'Seattle',
    'WA',
    null,
    'Buckley',
    'WA'
  ]);

  var regexp13 = new RegExp(r"(A)?(A.*)");
  shouldBe(regexp13.firstMatch('zxcasd;fl\ ^AaaAAaaaf;lrlrzs'),
      ['AaaAAaaaf;lrlrzs', null, 'AaaAAaaaf;lrlrzs']);

  var regexp14 = new RegExp(r"(a)|(b)");
  shouldBe(regexp14.firstMatch('b'), ['b', null, 'b']);

  var regexp15 = new RegExp(r"^(?!(ab)de|x)(abd)(f)");
  shouldBe(regexp15.firstMatch('abdf'), ['abdf', null, 'abd', 'f']);

  var regexp16 = new RegExp(r"(a|A)(b|B)");
  shouldBe(regexp16.firstMatch('abc'), ['ab', 'a', 'b']);

  var regexp17 = new RegExp(r"(a|d|q|)x", caseSensitive: false);
  shouldBe(regexp17.firstMatch('bcaDxqy'), ['Dx', 'D']);

  var regexp18 = new RegExp(r"^.*?(:|$)");
  shouldBe(regexp18.firstMatch('Hello: World'), ['Hello:', ':']);

  var regexp19 = new RegExp(r"(ab|^.{0,2})bar");
  shouldBe(regexp19.firstMatch('barrel'), ['bar', '']);

  var regexp20 = new RegExp(r"(?:(?!foo)...|^.{0,2})bar(.*)");
  shouldBe(regexp20.firstMatch('barrel'), ['barrel', 'rel']);
  shouldBe(regexp20.firstMatch('2barrel'), ['2barrel', 'rel']);

  var regexp21 = new RegExp(r"([a-g](b|B)|xyz)");
  shouldBe(regexp21.firstMatch('abc'), ['ab', 'ab', 'b']);

  var regexp22 = new RegExp(r"(?:^|;)\s*abc=([^;]*)");
  shouldBeNull(regexp22.firstMatch('abcdlskfgjdslkfg'));

  var regexp23 = new RegExp("\"[^<\"]*\"|'[^<']*'");
  shouldBe(regexp23.firstMatch('<html xmlns=\"http://www.w3.org/1999/xhtml\"'),
      ['\"http://www.w3.org/1999/xhtml\"']);

  var regexp24 = new RegExp(r"^(?:(?=abc)\w{3}:|\d\d)$");
  shouldBeNull(regexp24.firstMatch('123'));

  var regexp25 = new RegExp(r"^\s*(\*|[\w\-]+)(\b|$)?");
  shouldBe(regexp25.firstMatch('this is a test'), ['this', 'this', null]);
  shouldBeNull(regexp25.firstMatch('!this is a test'));

  var regexp26 = new RegExp(r"a(b)(a*)|aaa");
  shouldBe(regexp26.firstMatch('aaa'), ['aaa', null, null]);

  var regexp27 = new RegExp("^" +
          "(?:" +
          "([^:/?#]+):" + /* scheme */
          ")?" +
          "(?:" +
          "(//)" + /* authorityRoot */
          "(" + /* authority */
          "(?:" +
          "(" + /* userInfo */
          "([^:@]*)" + /* user */
          ":?" +
          "([^:@]*)" + /* password */
          ")?" +
          "@" +
          ")?" +
          "([^:/?#]*)" + /* domain */
          "(?::(\\d*))?" + /* port */
          ")" +
          ")?" +
          "([^?#]*)" + /*path*/
          "(?:\\?([^#]*))?" + /* queryString */
          "(?:#(.*))?" /*fragment */
      );
  shouldBe(
      regexp27
          .firstMatch('file:///Users/Someone/Desktop/HelloWorld/index.html'),
      [
        'file:///Users/Someone/Desktop/HelloWorld/index.html',
        'file',
        '//',
        '',
        null,
        null,
        null,
        '',
        null,
        '/Users/Someone/Desktop/HelloWorld/index.html',
        null,
        null
      ]);

  var regexp28 = new RegExp("^" +
      "(?:" +
      "([^:/?#]+):" + /* scheme */
      ")?" +
      "(?:" +
      "(//)" + /* authorityRoot */
      "(" + /* authority */
      "(" + /* userInfo */
      "([^:@]*)" + /* user */
      ":?" +
      "([^:@]*)" + /* password */
      ")?" +
      "@" +
      ")" +
      ")?");
  shouldBe(
      regexp28
          .firstMatch('file:///Users/Someone/Desktop/HelloWorld/index.html'),
      ['file:', 'file', null, null, null, null, null]);

  var regexp29 = new RegExp(r'^\s*((\[[^\]]+\])|(u?)("[^"]+"))\s*');
  shouldBeNull(regexp29.firstMatch('Committer:'));

  var regexp30 = new RegExp(r'^\s*((\[[^\]]+\])|m(u?)("[^"]+"))\s*');
  shouldBeNull(regexp30.firstMatch('Committer:'));

  var regexp31 = new RegExp(r'^\s*(m(\[[^\]]+\])|m(u?)("[^"]+"))\s*');
  shouldBeNull(regexp31.firstMatch('Committer:'));

  var regexp32 = new RegExp(r'\s*(m(\[[^\]]+\])|m(u?)("[^"]+"))\s*');
  shouldBeNull(regexp32.firstMatch('Committer:'));

  var regexp33 = new RegExp('^(?:(?:(a)(xyz|[^>"\'\s]*)?)|(/?>)|.[^\w\s>]*)');
  shouldBe(regexp33.firstMatch('> <head>'), ['>', null, null, '>']);

  var regexp34 = new RegExp(r"(?:^|\b)btn-\S+");
  shouldBeNull(regexp34.firstMatch('xyz123'));
  shouldBe(regexp34.firstMatch('btn-abc'), ['btn-abc']);
  shouldBeNull(regexp34.firstMatch('btn- abc'));
  shouldBeNull(regexp34.firstMatch('XXbtn-abc'));
  shouldBe(regexp34.firstMatch('XX btn-abc'), ['btn-abc']);

  var regexp35 = new RegExp(r"^((a|b)(x|xxx)|)$");
  shouldBe(regexp35.firstMatch('ax'), ['ax', 'ax', 'a', 'x']);
  shouldBeNull(regexp35.firstMatch('axx'));
  shouldBe(regexp35.firstMatch('axxx'), ['axxx', 'axxx', 'a', 'xxx']);
  shouldBe(regexp35.firstMatch('bx'), ['bx', 'bx', 'b', 'x']);
  shouldBeNull(regexp35.firstMatch('bxx'));
  shouldBe(regexp35.firstMatch('bxxx'), ['bxxx', 'bxxx', 'b', 'xxx']);

  var regexp36 = new RegExp(r"^((\/|\.|\-)(\d\d|\d\d\d\d)|)$");
  shouldBe(regexp36.firstMatch('/2011'), ['/2011', '/2011', '/', '2011']);
  shouldBe(regexp36.firstMatch('/11'), ['/11', '/11', '/', '11']);
  shouldBeNull(regexp36.firstMatch('/123'));

  var regexp37 = new RegExp(
      r"^([1][0-2]|[0]\d|\d)(\/|\.|\-)([0-2]\d|[3][0-1]|\d)((\/|\.|\-)(\d\d|\d\d\d\d)|)$");
  shouldBe(regexp37.firstMatch('7/4/1776'),
      ['7/4/1776', '7', '/', '4', '/1776', '/', '1776']);
  shouldBe(regexp37.firstMatch('07-04-1776'),
      ['07-04-1776', '07', '-', '04', '-1776', '-', '1776']);

  var regexp38 = new RegExp(r"^(z|(x|xx)|b|)$");
  shouldBe(regexp38.firstMatch('xx'), ['xx', 'xx', 'xx']);
  shouldBe(regexp38.firstMatch('b'), ['b', 'b', null]);
  shouldBe(regexp38.firstMatch('z'), ['z', 'z', null]);
  shouldBe(regexp38.firstMatch(''), ['', '', null]);

  var regexp39 = new RegExp(r"(8|((?=P)))?");
  shouldBe(regexp39.firstMatch(''), ['', null, null]);
  shouldBe(regexp39.firstMatch('8'), ['8', '8', null]);
  shouldBe(regexp39.firstMatch('zP'), ['', null, null]);

  var regexp40 = new RegExp(r"((8)|((?=P){4}))?()");
  shouldBe(regexp40.firstMatch(''), ['', null, null, null, '']);
  shouldBe(regexp40.firstMatch('8'), ['8', '8', '8', null, '']);
  shouldBe(regexp40.firstMatch('zPz'), ['', null, null, null, '']);
  shouldBe(regexp40.firstMatch('zPPz'), ['', null, null, null, '']);
  shouldBe(regexp40.firstMatch('zPPPz'), ['', null, null, null, '']);
  shouldBe(regexp40.firstMatch('zPPPPz'), ['', null, null, null, '']);

  var regexp41 = new RegExp(
      r"(([\w\-]+:\/\/?|www[.])[^\s()<>]+(?:([\w\d]+)|([^\[:punct:\]\s()<>\W]|\/)))");
  shouldBe(
      regexp41.firstMatch(
          'Here is a link: http://www.acme.com/our_products/index.html. That is all we want!'),
      [
        'http://www.acme.com/our_products/index.html',
        'http://www.acme.com/our_products/index.html',
        'http://',
        'l',
        null
      ]);

  var regexp42 = new RegExp(r"((?:(4)?))?");
  shouldBe(regexp42.firstMatch(''), ['', null, null]);
  shouldBe(regexp42.firstMatch('4'), ['4', '4', '4']);
  shouldBe(regexp42.firstMatch('4321'), ['4', '4', '4']);

  shouldBeTrue(new RegExp(r"(?!(?=r{0}){2,})|((z)?)?", caseSensitive: false)
      .hasMatch(''));

  var regexp43 = new RegExp(r"(?!(?:\1+s))");
  shouldBe(regexp43.firstMatch('SSS'), ['']);

  var regexp44 = new RegExp(r"(?!(?:\3+(s+?)))");
  shouldBe(regexp44.firstMatch('SSS'), ['', null]);

  var regexp45 = new RegExp(r"((?!(?:|)v{2,}|))");
  shouldBeNull(regexp45.firstMatch('vt'));

  var regexp46 = new RegExp(r"(w)(?:5{3}|())|pk");
  shouldBeNull(regexp46.firstMatch('5'));
  shouldBe(regexp46.firstMatch('pk'), ['pk', null, null]);
  shouldBe(regexp46.firstMatch('Xw555'), ['w555', 'w', null]);
  shouldBe(regexp46.firstMatch('Xw55pk5'), ['w', 'w', '']);

  var regexp47 = new RegExp(r"(.*?)(?:(?:\?(.*?)?)?)(?:(?:#)?)$");
  shouldBe(regexp47.firstMatch('/www.acme.com/this/is/a/path/file.txt'), [
    '/www.acme.com/this/is/a/path/file.txt',
    '/www.acme.com/this/is/a/path/file.txt',
    null
  ]);

  var regexp48 = new RegExp(
      r"^(?:(\w+):\/*([\w\.\-\d]+)(?::(\d+)|)(?=(?:\/|$))|)(?:$|\/?(.*?)(?:\?(.*?)?|)(?:#(.*)|)$)");
  shouldBe(regexp48.firstMatch('http://www.acme.com/this/is/a/path/file.txt'), [
    'http://www.acme.com/this/is/a/path/file.txt',
    'http',
    'www.acme.com',
    null,
    'this/is/a/path/file.txt',
    null,
    null
  ]);

  var regexp49 = new RegExp(
      r"(?:([^:]*?)(?:(?:\?(.*?)?)?)(?:(?:#)?)$)|(?:^(?:(\w+):\/*([\w\.\-\d]+)(?::(\d+)|)(?=(?:\/|$))|)(?:$|\/?(.*?)(?:\?(.*?)?|)(?:#(.*)|)$))");
  shouldBe(regexp49.firstMatch('http://www.acme.com/this/is/a/path/file.txt'), [
    'http://www.acme.com/this/is/a/path/file.txt',
    null,
    null,
    'http',
    'www.acme.com',
    null,
    'this/is/a/path/file.txt',
    null,
    null
  ]);

  var regexp50 = new RegExp(r"((a)b{28,}c|d)x");
  shouldBeNull(regexp50.firstMatch('((a)b{28,}c|d)x'));
  shouldBe(regexp50.firstMatch('abbbbbbbbbbbbbbbbbbbbbbbbbbbbcx'), [
    'abbbbbbbbbbbbbbbbbbbbbbbbbbbbcx',
    'abbbbbbbbbbbbbbbbbbbbbbbbbbbbc',
    'a'
  ]);
  shouldBe(regexp50.firstMatch('dx'), ['dx', 'd', null]);

  var s = "((.\s{-}).{28,}\P{Yi}?{,30}\|.)\x9e{-,}\P{Any}";
  var regexp51 = new RegExp(s);
  shouldBeNull(regexp51.firstMatch('abc'));
  shouldBe(regexp51.firstMatch(s), [')\x9e{-,}P{Any}', ')', null]);

  var regexp52 = new RegExp(r"(Rob)|(Bob)|(Robert)|(Bobby)");
  shouldBe(regexp52.firstMatch('Hi Bob'), ['Bob', null, 'Bob', null, null]);

  // Test cases discovered by fuzzing that crashed the compiler.
  var regexp53 = new RegExp(
      r"(?=(?:(?:(gB)|(?!cs|<))((?=(?!v6){0,})))|(?=#)+?)",
      multiLine: true);
  shouldBe(regexp53.firstMatch('#'), ['', null, '']);
  var regexp54 = new RegExp(r"((?:(?:()|(?!))((?=(?!))))|())", multiLine: true);
  shouldBe(regexp54.firstMatch('#'), ['', '', null, null, '']);
  var regexp55 = new RegExp(r"(?:(?:(?:a?|(?:))((?:)))|a?)", multiLine: true);
  shouldBe(regexp55.firstMatch('#'), ['', '']);

  // Test evaluation order of empty subpattern alternatives.
  var regexp56 = new RegExp(r"(|a)");
  shouldBe(regexp56.firstMatch('a'), ['', '']);
  var regexp57 = new RegExp(r"(a|)");
  shouldBe(regexp57.firstMatch('a'), ['a', 'a']);

  // Tests that non-greedy repeat quantified parentheses will backtrack through multiple frames of subpattern matches.
  var regexp58 = new RegExp(r"a|b(?:[^b])*?c");
  shouldBe(regexp58.firstMatch('badbc'), ['a']);
  var regexp59 = new RegExp(r"(X(?:.(?!X))*?Y)|(Y(?:.(?!Y))*?Z)");
  Expect.listEquals(
      regexp59
          .allMatches('Y aaa X Match1 Y aaa Y Match2 Z')
          .map((m) => m.group(0))
          .toList(),
      ['X Match1 Y', 'Y Match2 Z']);
}
