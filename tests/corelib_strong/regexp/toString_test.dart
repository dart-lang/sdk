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
  dynamic testForwardSlash(pattern, _string)
  {
      var string = _string;

      var re1 = new RegExp(pattern);

      return re1.hasMatch(string);
  }

  dynamic testLineTerminator(pattern)
  {
      var re1 = new RegExp(pattern);

      return new RegExp(r"\n|\r|\u2028|\u2029").hasMatch(re1.toString());
  }

  // These strings are equivalent, since the '\' is identity escaping the '/' at the string level.
  shouldBeTrue(testForwardSlash("^/\$", "/"));
  shouldBeTrue(testForwardSlash("^\/\$", "/"));
  // This string passes "^\/$" to the RegExp, so the '/' is escaped in the re!
  shouldBeTrue(testForwardSlash("^\\/\$", "/"));
  // These strings pass "^\\/$" and "^\\\/$" respectively to the RegExp, giving one '\' to match.
  shouldBeTrue(testForwardSlash("^\\\\/\$", "\\/"));
  shouldBeTrue(testForwardSlash("^\\\\\\/\$", "\\/"));
  // These strings match two backslashes (the second with the '/' escaped).
  shouldBeTrue(testForwardSlash("^\\\\\\\\/\$", "\\\\/"));
  shouldBeTrue(testForwardSlash("^\\\\\\\\\\/\$", "\\\\/"));
  // Test that nothing goes wrongif there are multiple forward slashes!
  shouldBeTrue(testForwardSlash("x/x/x", "x/x/x"));
  shouldBeTrue(testForwardSlash("x\\/x/x", "x/x/x"));
  shouldBeTrue(testForwardSlash("x/x\\/x", "x/x/x"));
  shouldBeTrue(testForwardSlash("x\\/x\\/x", "x/x/x"));

  shouldBeFalse(testLineTerminator("\\n"));
  shouldBeFalse(testLineTerminator("\\\\n"));
  shouldBeFalse(testLineTerminator("\\r"));
  shouldBeFalse(testLineTerminator("\\\\r"));
  shouldBeFalse(testLineTerminator("\\u2028"));
  shouldBeFalse(testLineTerminator("\\\\u2028"));
  shouldBeFalse(testLineTerminator("\\u2029"));
  shouldBeFalse(testLineTerminator("\\\\u2029"));
}
