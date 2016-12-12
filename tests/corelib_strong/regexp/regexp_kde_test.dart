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
  description("KDE JS Test");

  var ri = new RegExp(r"a", caseSensitive: false);
  var rm = new RegExp(r"a", multiLine: true);
  var rg = new RegExp(r"a");

  shouldBe(new RegExp(r"(b)c").firstMatch('abcd'), ["bc", "b"]);

  shouldBe(firstMatch('abcdefghi', new RegExp(r"(abc)def(ghi)")), ['abcdefghi', 'abc', 'ghi']);
  shouldBe(new RegExp(r"(abc)def(ghi)").firstMatch('abcdefghi'), ['abcdefghi', 'abc', 'ghi']);

  shouldBe(firstMatch('abcdefghi', new RegExp(r"(a(b(c(d(e)f)g)h)i)")), ['abcdefghi', 'abcdefghi', 'bcdefgh', 'cdefg', 'def', 'e']);

  shouldBe(firstMatch('(100px 200px 150px 15px)', new RegExp(r"\((\d+)(px)* (\d+)(px)* (\d+)(px)* (\d+)(px)*\)")),
          ['(100px 200px 150px 15px)', '100', 'px', '200', 'px', '150', 'px', '15', 'px']);
  shouldBeNull(firstMatch('', new RegExp(r"\((\d+)(px)* (\d+)(px)* (\d+)(px)* (\d+)(px)*\)")));

  var invalidChars = new RegExp(r"[^@\.\w]"); // #47092
  shouldBeTrue(firstMatch('faure@kde.org', invalidChars) == null);
  shouldBeFalse(firstMatch('faure-kde@kde.org', invalidChars) == null);

  assertEquals('test1test2'.replaceAll('test','X'),'X1X2');
  assertEquals('test1test2'.replaceAll(new RegExp(r"\d"),'X'),'testXtestX');
  assertEquals('1test2test3'.replaceAll(new RegExp(r"\d"),''),'testtest');
  assertEquals('test1test2'.replaceAll(new RegExp(r"test"),'X'),'X1X2');
  assertEquals('1test2test3'.replaceAll(new RegExp(r"\d"),''),'testtest');
  assertEquals('1test2test3'.replaceAll(new RegExp(r"x"),''),'1test2test3');
  assertEquals('test1test2'.replaceAllMapped(new RegExp(r"(te)(st)"),
              (m) => "${m.group(2)}${m.group(1)}"),'stte1stte2');
  assertEquals('foo+bar'.replaceAll(new RegExp(r"\+"),'%2B'), 'foo%2Bbar');
  var caught = false; try { new RegExp("+"); } catch (e) { caught = true; }
  shouldBeTrue(caught); // #40435
  assertEquals('foo'.replaceAll(new RegExp(r"z?"),'x'), 'xfxoxox');
  assertEquals('test test'.replaceAll(new RegExp(r"\s*"),''),'testtest'); // #50985
  assertEquals('abc\$%@'.replaceAll(new RegExp(r"[^0-9a-z]*", caseSensitive: false),''),'abc'); // #50848
  assertEquals('ab'.replaceAll(new RegExp(r"[^\d\.]*", caseSensitive: false),''),''); // #75292
  assertEquals('1ab'.replaceAll(new RegExp(r"[^\d\.]*", caseSensitive: false),''),'1'); // #75292

  Expect.listEquals('1test2test3blah'.split(new RegExp(r"test")), ['1', '2', '3blah']);
  var reg = new RegExp(r"(\d\d )");
  var str = '98 76 blah';
  shouldBe(reg.firstMatch(str),['98 ', '98 ']);

  str = "For more information, see Chapter 3.4.5.1";
  var re = new RegExp(r"(chapter \d+(\.\d)*)", caseSensitive: false);
  // This returns the array containing Chapter 3.4.5.1,Chapter 3.4.5.1,.1
  // 'Chapter 3.4.5.1' is the first match and the first value remembered from (Chapter \d+(\.\d)*).
  // '.1' is the second value remembered from (\.\d)
  shouldBe(firstMatch(str, re),['Chapter 3.4.5.1', 'Chapter 3.4.5.1', '.1']);

  str = "abcDdcba";
  // The returned array contains D, d.
  re = new RegExp(r"d", caseSensitive: false);
  var matches = re.allMatches(str);
  Expect.listEquals(
      matches.map((m) => m.group(0)).toList(),
      ['D', 'd']);

  // unicode escape sequence
  shouldBe(firstMatch('abc', new RegExp(r"\u0062")), ['b']);
}
