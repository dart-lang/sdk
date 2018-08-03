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
      'Tests for bug <a href="https://bugs.webkit.org/show_bug.cgi?id=21232">#21232</a>, and related range issues described in bug.');

  // Basic test for ranges - one to three and five are in regexp, four is not, and '-' should not match
  var regexp01 = new RegExp(r"[1-35]+").firstMatch("-12354");
  shouldBe(regexp01, ["1235"]);
  // Tests inserting an escape character class into the above pattern - where the spaces fall within the
  // range it is no longer a range - hyphens should now match, two should not.
  var regexp01a = new RegExp(r"[\s1-35]+").firstMatch("-123 54");
  shouldBe(regexp01a, ["123 5"]);

  // These are invalid ranges, according to ECMA-262, but we allow them.
  var regexp01b = new RegExp(r"[1\s-35]+").firstMatch("21-3 54");
  shouldBe(regexp01b, ["1-3 5"]);
  var regexp01c = new RegExp(r"[1-\s35]+").firstMatch("21-3 54");
  shouldBe(regexp01c, ["1-3 5"]);

  var regexp01d = new RegExp(r"[1-3\s5]+").firstMatch("-123 54");
  shouldBe(regexp01d, ["123 5"]);
  var regexp01e = new RegExp(r"[1-35\s5]+").firstMatch("-123 54");
  shouldBe(regexp01e, ["123 5"]);
  // hyphens are normal characters if a range is not fully specified.
  var regexp01f = new RegExp(r"[-3]+").firstMatch("2-34");
  shouldBe(regexp01f, ["-3"]);
  var regexp01g = new RegExp(r"[2-]+").firstMatch("12-3");
  shouldBe(regexp01g, ["2-"]);

  // Similar to the above tests, but where the hyphen is escaped this is never a range.
  var regexp02 = new RegExp(r"[1\-35]+").firstMatch("21-354");
  shouldBe(regexp02, ["1-35"]);
  // As above.
  var regexp02a = new RegExp(r"[\s1\-35]+").firstMatch("21-3 54");
  shouldBe(regexp02a, ["1-3 5"]);
  var regexp02b = new RegExp(r"[1\s\-35]+").firstMatch("21-3 54");
  shouldBe(regexp02b, ["1-3 5"]);
  var regexp02c = new RegExp(r"[1\-\s35]+").firstMatch("21-3 54");
  shouldBe(regexp02c, ["1-3 5"]);
  var regexp02d = new RegExp(r"[1\-3\s5]+").firstMatch("21-3 54");
  shouldBe(regexp02d, ["1-3 5"]);
  var regexp02e = new RegExp(r"[1\-35\s5]+").firstMatch("21-3 54");
  shouldBe(regexp02e, ["1-3 5"]);

  // Test that an escaped hyphen can be used as a bound on a range.
  var regexp03a = new RegExp(r"[\--0]+").firstMatch(",-.01");
  shouldBe(regexp03a, ["-.0"]);
  var regexp03b = new RegExp(r"[+-\-]+").firstMatch("*+,-.");
  shouldBe(regexp03b, ["+,-"]);

  // The actual bug reported.
  var bug21232 =
      (new RegExp(r"^[,:{}\[\]0-9.\-+Eaeflnr-u \n\r\t]*$")).hasMatch('@');
  shouldBeFalse(bug21232);
}
