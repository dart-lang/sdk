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

  var regexp1 = new RegExp(r".*blah.*");
  shouldBeNull(regexp1.firstMatch('test'));
  shouldBe(regexp1.firstMatch('blah'), ['blah']);
  shouldBe(regexp1.firstMatch('1blah'), ['1blah']);
  shouldBe(regexp1.firstMatch('blah1'), ['blah1']);
  shouldBe(regexp1.firstMatch('blah blah blah'), ['blah blah blah']);
  shouldBe(regexp1.firstMatch('blah\nsecond'), ['blah']);
  shouldBe(regexp1.firstMatch('first\nblah'), ['blah']);
  shouldBe(regexp1.firstMatch('first\nblah\nthird'), ['blah']);
  shouldBe(regexp1.firstMatch('first\nblah2\nblah3'), ['blah2']);

  var regexp2 = new RegExp(r"^.*blah.*");
  shouldBeNull(regexp2.firstMatch('test'));
  shouldBe(regexp2.firstMatch('blah'), ['blah']);
  shouldBe(regexp2.firstMatch('1blah'), ['1blah']);
  shouldBe(regexp2.firstMatch('blah1'), ['blah1']);
  shouldBe(regexp2.firstMatch('blah blah blah'), ['blah blah blah']);
  shouldBe(regexp2.firstMatch('blah\nsecond'), ['blah']);
  shouldBeNull(regexp2.firstMatch('first\nblah'));
  shouldBeNull(regexp2.firstMatch('first\nblah\nthird'));
  shouldBeNull(regexp2.firstMatch('first\nblah2\nblah3'));

  var regexp3 = new RegExp(r".*blah.*$");
  shouldBeNull(regexp3.firstMatch('test'));
  shouldBe(regexp3.firstMatch('blah'), ['blah']);
  shouldBe(regexp3.firstMatch('1blah'), ['1blah']);
  shouldBe(regexp3.firstMatch('blah1'), ['blah1']);
  shouldBe(regexp3.firstMatch('blah blah blah'), ['blah blah blah']);
  shouldBeNull(regexp3.firstMatch('blah\nsecond'));
  shouldBe(regexp3.firstMatch('first\nblah'), ['blah']);
  shouldBeNull(regexp3.firstMatch('first\nblah\nthird'));
  shouldBe(regexp3.firstMatch('first\nblah2\nblah3'), ['blah3']);

  var regexp4 = new RegExp(r"^.*blah.*$");
  shouldBeNull(regexp4.firstMatch('test'));
  shouldBe(regexp4.firstMatch('blah'), ['blah']);
  shouldBe(regexp4.firstMatch('1blah'), ['1blah']);
  shouldBe(regexp4.firstMatch('blah1'), ['blah1']);
  shouldBe(regexp4.firstMatch('blah blah blah'), ['blah blah blah']);
  shouldBeNull(regexp4.firstMatch('blah\nsecond'));
  shouldBeNull(regexp4.firstMatch('first\nblah'));
  shouldBeNull(regexp4.firstMatch('first\nblah\nthird'));
  shouldBeNull(regexp4.firstMatch('first\nblah2\nblah3'));

  var regexp5 = new RegExp(r".*?blah.*");
  shouldBeNull(regexp5.firstMatch('test'));
  shouldBe(regexp5.firstMatch('blah'), ['blah']);
  shouldBe(regexp5.firstMatch('1blah'), ['1blah']);
  shouldBe(regexp5.firstMatch('blah1'), ['blah1']);
  shouldBe(regexp5.firstMatch('blah blah blah'), ['blah blah blah']);
  shouldBe(regexp5.firstMatch('blah\nsecond'), ['blah']);
  shouldBe(regexp5.firstMatch('first\nblah'), ['blah']);
  shouldBe(regexp5.firstMatch('first\nblah\nthird'), ['blah']);
  shouldBe(regexp5.firstMatch('first\nblah2\nblah3'), ['blah2']);

  var regexp6 = new RegExp(r".*blah.*?");
  shouldBeNull(regexp6.firstMatch('test'));
  shouldBe(regexp6.firstMatch('blah'), ['blah']);
  shouldBe(regexp6.firstMatch('1blah'), ['1blah']);
  shouldBe(regexp6.firstMatch('blah1'), ['blah']);
  shouldBe(regexp6.firstMatch('blah blah blah'), ['blah blah blah']);
  shouldBe(regexp6.firstMatch('blah\nsecond'), ['blah']);
  shouldBe(regexp6.firstMatch('first\nblah'), ['blah']);
  shouldBe(regexp6.firstMatch('first\nblah\nthird'), ['blah']);
  shouldBe(regexp6.firstMatch('first\nblah2\nblah3'), ['blah']);

  var regexp7 = new RegExp(r"^.*?blah.*?$");
  shouldBeNull(regexp7.firstMatch('test'));
  shouldBe(regexp7.firstMatch('blah'), ['blah']);
  shouldBe(regexp7.firstMatch('1blah'), ['1blah']);
  shouldBe(regexp7.firstMatch('blah1'), ['blah1']);
  shouldBe(regexp7.firstMatch('blah blah blah'), ['blah blah blah']);
  shouldBeNull(regexp7.firstMatch('blah\nsecond'));
  shouldBeNull(regexp7.firstMatch('first\nblah'));
  shouldBeNull(regexp7.firstMatch('first\nblah\nthird'));
  shouldBeNull(regexp7.firstMatch('first\nblah2\nblah3'));

  var regexp8 = new RegExp(r"^(.*)blah.*$");
  shouldBeNull(regexp8.firstMatch('test'));
  shouldBe(regexp8.firstMatch('blah'), ['blah','']);
  shouldBe(regexp8.firstMatch('1blah'), ['1blah','1']);
  shouldBe(regexp8.firstMatch('blah1'), ['blah1','']);
  shouldBe(regexp8.firstMatch('blah blah blah'), ['blah blah blah','blah blah ']);
  shouldBeNull(regexp8.firstMatch('blah\nsecond'));
  shouldBeNull(regexp8.firstMatch('first\nblah'));
  shouldBeNull(regexp8.firstMatch('first\nblah\nthird'));
  shouldBeNull(regexp8.firstMatch('first\nblah2\nblah3'));

  var regexp9 = new RegExp(r".*blah.*", multiLine: true);
  shouldBeNull(regexp9.firstMatch('test'));
  shouldBe(regexp9.firstMatch('blah'), ['blah']);
  shouldBe(regexp9.firstMatch('1blah'), ['1blah']);
  shouldBe(regexp9.firstMatch('blah1'), ['blah1']);
  shouldBe(regexp9.firstMatch('blah blah blah'), ['blah blah blah']);
  shouldBe(regexp9.firstMatch('blah\nsecond'), ['blah']);
  shouldBe(regexp9.firstMatch('first\nblah'), ['blah']);
  shouldBe(regexp9.firstMatch('first\nblah\nthird'), ['blah']);
  shouldBe(regexp9.firstMatch('first\nblah2\nblah3'), ['blah2']);

  var regexp10 = new RegExp(r"^.*blah.*", multiLine: true);
  shouldBeNull(regexp10.firstMatch('test'));
  shouldBe(regexp10.firstMatch('blah'), ['blah']);
  shouldBe(regexp10.firstMatch('1blah'), ['1blah']);
  shouldBe(regexp10.firstMatch('blah1'), ['blah1']);
  shouldBe(regexp10.firstMatch('blah blah blah'), ['blah blah blah']);
  shouldBe(regexp10.firstMatch('blah\nsecond'), ['blah']);
  shouldBe(regexp10.firstMatch('first\nblah'), ['blah']);
  shouldBe(regexp10.firstMatch('first\nblah\nthird'), ['blah']);
  shouldBe(regexp10.firstMatch('first\nblah2\nblah3'), ['blah2']);

  var regexp11 = new RegExp(r".*(?:blah).*$");
  shouldBeNull(regexp11.firstMatch('test'));
  shouldBe(regexp11.firstMatch('blah'), ['blah']);
  shouldBe(regexp11.firstMatch('1blah'), ['1blah']);
  shouldBe(regexp11.firstMatch('blah1'), ['blah1']);
  shouldBe(regexp11.firstMatch('blah blah blah'), ['blah blah blah']);
  shouldBeNull(regexp11.firstMatch('blah\nsecond'));
  shouldBe(regexp11.firstMatch('first\nblah'), ['blah']);
  shouldBeNull(regexp11.firstMatch('first\nblah\nthird'));
  shouldBe(regexp11.firstMatch('first\nblah2\nblah3'), ['blah3']);

  var regexp12 = new RegExp(r".*(?:blah|buzz|bang).*$");
  shouldBeNull(regexp12.firstMatch('test'));
  shouldBe(regexp12.firstMatch('blah'), ['blah']);
  shouldBe(regexp12.firstMatch('1blah'), ['1blah']);
  shouldBe(regexp12.firstMatch('blah1'), ['blah1']);
  shouldBe(regexp12.firstMatch('blah blah blah'), ['blah blah blah']);
  shouldBeNull(regexp12.firstMatch('blah\nsecond'));
  shouldBe(regexp12.firstMatch('first\nblah'), ['blah']);
  shouldBeNull(regexp12.firstMatch('first\nblah\nthird'));
  shouldBe(regexp12.firstMatch('first\nblah2\nblah3'), ['blah3']);

  var regexp13 = new RegExp(r".*\n\d+.*");
  shouldBe(regexp13.firstMatch('abc\n123'), ['abc\n123']);
}
