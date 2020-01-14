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
      'Test regular expression processing with alternatives that match consuming no characters');

  var emptyStr = "";
  var s1 = "xxxx";
  var s2 = "aaaa";
  var s3 = "aax";
  var s4 = "abab";
  var s5 = "ab";
  var s6 = "xabx";
  var s7 = "g0";

  // Non-capturing empty first alternative greedy '*'
  var re1 = new RegExp(r"(?:|a|z)*");
  shouldBe(firstMatch(emptyStr, re1), [""]);
  shouldBe(firstMatch(s1, re1), [""]);
  shouldBe(firstMatch(s2, re1), ["aaaa"]);
  shouldBe(firstMatch(s3, re1), ["aa"]);

  // Non-capturing empty middle alternative greedy '*'
  var re2 = new RegExp(r"(?:a||z)*");
  shouldBe(firstMatch(emptyStr, re2), [""]);
  shouldBe(firstMatch(s1, re2), [""]);
  shouldBe(firstMatch(s2, re2), ["aaaa"]);
  shouldBe(firstMatch(s3, re2), ["aa"]);

  // Non-capturing empty last alternative greedy '*'
  var re3 = new RegExp(r"(?:a|z|)*");
  shouldBe(firstMatch(emptyStr, re3), [""]);
  shouldBe(firstMatch(s1, re3), [""]);
  shouldBe(firstMatch(s2, re3), ["aaaa"]);
  shouldBe(firstMatch(s3, re3), ["aa"]);

  // Capturing empty first alternative greedy '*'
  var re4 = new RegExp(r"(|a|z)*");
  shouldBe(firstMatch(emptyStr, re4), ["", null]);
  shouldBe(firstMatch(s1, re4), ["", null]);
  shouldBe(firstMatch(s2, re4), ["aaaa", "a"]);
  shouldBe(firstMatch(s3, re4), ["aa", "a"]);

  // Capturing empty middle alternative greedy '*'
  var re5 = new RegExp(r"(a||z)*");
  shouldBe(firstMatch(emptyStr, re5), ["", null]);
  shouldBe(firstMatch(s1, re5), ["", null]);
  shouldBe(firstMatch(s2, re5), ["aaaa", "a"]);
  shouldBe(firstMatch(s3, re5), ["aa", "a"]);

  // Capturing empty last alternative greedy '*'
  var re6 = new RegExp(r"(a|z|)*");
  shouldBe(firstMatch(emptyStr, re6), ["", null]);
  shouldBe(firstMatch(s1, re6), ["", null]);
  shouldBe(firstMatch(s2, re6), ["aaaa", "a"]);
  shouldBe(firstMatch(s3, re6), ["aa", "a"]);

  // Non-capturing empty first alternative fixed-count
  var re7 = new RegExp(r"(?:|a|z){2,5}");
  shouldBe(firstMatch(emptyStr, re7), [""]);
  shouldBe(firstMatch(s1, re7), [""]);
  shouldBe(firstMatch(s2, re7), ["aaa"]);
  shouldBe(firstMatch(s3, re7), ["aa"]);

  // Non-capturing empty middle alternative fixed-count
  var re8 = new RegExp(r"(?:a||z){2,5}");
  shouldBe(firstMatch(emptyStr, re8), [""]);
  shouldBe(firstMatch(s1, re8), [""]);
  shouldBe(firstMatch(s2, re8), ["aaaa"]);
  shouldBe(firstMatch(s3, re8), ["aa"]);

  // Non-capturing empty last alternative fixed-count
  var re9 = new RegExp(r"(?:a|z|){2,5}");
  shouldBe(firstMatch(emptyStr, re9), [""]);
  shouldBe(firstMatch(s1, re9), [""]);
  shouldBe(firstMatch(s2, re9), ["aaaa"]);
  shouldBe(firstMatch(s3, re9), ["aa"]);

  // Non-capturing empty first alternative non-greedy '*'
  var re10 = new RegExp(r"(?:|a|z)*?");
  shouldBe(firstMatch(emptyStr, re10), [""]);
  shouldBe(firstMatch(s1, re10), [""]);
  shouldBe(firstMatch(s2, re10), [""]);
  shouldBe(firstMatch(s3, re10), [""]);

  // Non-capturing empty middle alternative non-greedy '*'
  var re11 = new RegExp(r"(?:a||z)*?");
  shouldBe(firstMatch(emptyStr, re11), [""]);
  shouldBe(firstMatch(s1, re11), [""]);
  shouldBe(firstMatch(s2, re11), [""]);
  shouldBe(firstMatch(s3, re11), [""]);

  // Non-capturing empty last alternative non-greedy '*'
  var re12 = new RegExp(r"(?:a|z|)*?");
  shouldBe(firstMatch(emptyStr, re12), [""]);
  shouldBe(firstMatch(s1, re12), [""]);
  shouldBe(firstMatch(s2, re12), [""]);
  shouldBe(firstMatch(s3, re12), [""]);

  // Capturing empty first alternative non-greedy '*'
  var re13 = new RegExp(r"(|a|z)*?");
  shouldBe(firstMatch(emptyStr, re13), ["", null]);
  shouldBe(firstMatch(s1, re13), ["", null]);
  shouldBe(firstMatch(s2, re13), ["", null]);
  shouldBe(firstMatch(s3, re13), ["", null]);

  // Capturing empty middle alternative non-greedy '*'
  var re14 = new RegExp(r"(a||z)*?");
  shouldBe(firstMatch(emptyStr, re14), ["", null]);
  shouldBe(firstMatch(s1, re14), ["", null]);
  shouldBe(firstMatch(s2, re14), ["", null]);
  shouldBe(firstMatch(s3, re14), ["", null]);

  // Capturing empty last alternative non-greedy '*'
  var re15 = new RegExp(r"(a|z|)*?");
  shouldBe(firstMatch(emptyStr, re15), ["", null]);
  shouldBe(firstMatch(s1, re15), ["", null]);
  shouldBe(firstMatch(s2, re15), ["", null]);
  shouldBe(firstMatch(s3, re15), ["", null]);

  // Non-capturing empty first alternative greedy '?'
  var re16 = new RegExp(r"(?:|a|z)?");
  shouldBe(firstMatch(emptyStr, re16), [""]);
  shouldBe(firstMatch(s1, re16), [""]);
  shouldBe(firstMatch(s2, re16), ["a"]);
  shouldBe(firstMatch(s3, re16), ["a"]);

  // Non-capturing empty middle alternative greedy '?'
  var re17 = new RegExp(r"(?:a||z)?");
  shouldBe(firstMatch(emptyStr, re17), [""]);
  shouldBe(firstMatch(s1, re17), [""]);
  shouldBe(firstMatch(s2, re17), ["a"]);
  shouldBe(firstMatch(s3, re17), ["a"]);

  // Non-capturing empty last alternative greedy '?'
  var re18 = new RegExp(r"(?:a|z|)?");
  shouldBe(firstMatch(emptyStr, re18), [""]);
  shouldBe(firstMatch(s1, re18), [""]);
  shouldBe(firstMatch(s2, re18), ["a"]);
  shouldBe(firstMatch(s3, re18), ["a"]);

  // Capturing empty first alternative greedy '?'
  var re19 = new RegExp(r"(|a|z)?");
  shouldBe(firstMatch(emptyStr, re19), ["", null]);
  shouldBe(firstMatch(s1, re19), ["", null]);
  shouldBe(firstMatch(s2, re19), ["a", "a"]);
  shouldBe(firstMatch(s3, re19), ["a", "a"]);

  // Capturing empty middle alternative greedy '?'
  var re20 = new RegExp(r"(a||z)?");
  shouldBe(firstMatch(emptyStr, re20), ["", null]);
  shouldBe(firstMatch(s1, re20), ["", null]);
  shouldBe(firstMatch(s2, re20), ["a", "a"]);
  shouldBe(firstMatch(s3, re20), ["a", "a"]);

  // Capturing empty last alternative greedy '?'
  var re21 = new RegExp(r"(a|z|)?");
  shouldBe(firstMatch(emptyStr, re21), ["", null]);
  shouldBe(firstMatch(s1, re21), ["", null]);
  shouldBe(firstMatch(s2, re21), ["a", "a"]);
  shouldBe(firstMatch(s3, re21), ["a", "a"]);

  // Non-capturing empty first alternative non-greedy '?'
  var re22 = new RegExp(r"(?:|a|z)??");
  shouldBe(firstMatch(emptyStr, re22), [""]);
  shouldBe(firstMatch(s1, re22), [""]);
  shouldBe(firstMatch(s2, re22), [""]);
  shouldBe(firstMatch(s3, re22), [""]);

  // Non-capturing empty middle alternative non-greedy '?'
  var re23 = new RegExp(r"(?:a||z)??");
  shouldBe(firstMatch(emptyStr, re23), [""]);
  shouldBe(firstMatch(s1, re23), [""]);
  shouldBe(firstMatch(s2, re23), [""]);
  shouldBe(firstMatch(s3, re23), [""]);

  // Non-capturing empty last alternative non-greedy '?'
  var re24 = new RegExp(r"(?:a|z|)??");
  shouldBe(firstMatch(emptyStr, re24), [""]);
  shouldBe(firstMatch(s1, re24), [""]);
  shouldBe(firstMatch(s2, re24), [""]);
  shouldBe(firstMatch(s3, re24), [""]);

  // Capturing empty first alternative non-greedy '?'
  var re25 = new RegExp(r"(|a|z)??");
  shouldBe(firstMatch(emptyStr, re25), ["", null]);
  shouldBe(firstMatch(s1, re25), ["", null]);
  shouldBe(firstMatch(s2, re25), ["", null]);
  shouldBe(firstMatch(s3, re25), ["", null]);

  // Capturing empty middle alternative non-greedy '?'
  var re26 = new RegExp(r"(a||z)??");
  shouldBe(firstMatch(emptyStr, re26), ["", null]);
  shouldBe(firstMatch(s1, re26), ["", null]);
  shouldBe(firstMatch(s2, re26), ["", null]);
  shouldBe(firstMatch(s3, re26), ["", null]);

  // Capturing empty last alternative non-greedy '?'
  var re27 = new RegExp(r"(a|z|)??");
  shouldBe(firstMatch(emptyStr, re27), ["", null]);
  shouldBe(firstMatch(s1, re27), ["", null]);
  shouldBe(firstMatch(s2, re27), ["", null]);
  shouldBe(firstMatch(s3, re27), ["", null]);

  // Non-capturing empty first alternative greedy '*' non-terminal
  var re28 = new RegExp(r"(?:|a|z)*x");
  shouldBe(firstMatch(emptyStr, re28), null);
  shouldBe(firstMatch(s1, re28), ["x"]);
  shouldBe(firstMatch(s2, re28), null);
  shouldBe(firstMatch(s3, re28), ["aax"]);

  // Non-capturing empty middle alternative greedy '*' non-terminal
  var re29 = new RegExp(r"(?:a||z)*x");
  shouldBe(firstMatch(emptyStr, re29), null);
  shouldBe(firstMatch(s1, re29), ["x"]);
  shouldBe(firstMatch(s2, re29), null);
  shouldBe(firstMatch(s3, re29), ["aax"]);

  // Non-capturing empty last alternative greedy '*' non-terminal
  var re30 = new RegExp(r"(?:a|z|)*x");
  shouldBe(firstMatch(emptyStr, re30), null);
  shouldBe(firstMatch(s1, re30), ["x"]);
  shouldBe(firstMatch(s2, re30), null);
  shouldBe(firstMatch(s3, re30), ["aax"]);

  // Non-capturing two possibly empty alternatives greedy '*'
  var re31 = new RegExp(r"(?:a*|b*)*");
  shouldBe(firstMatch(emptyStr, re31), [""]);
  shouldBe(firstMatch(s1, re31), [""]);
  shouldBe(firstMatch(s3, re31), ["aa"]);
  shouldBe(firstMatch(s4, re31), ["abab"]);

  // Non-capturing two possibly empty non-greedy alternatives non-greedy '*'
  var re32 = new RegExp(r"(?:a*?|b*?)*");
  shouldBe(firstMatch(emptyStr, re32), [""]);
  shouldBe(firstMatch(s1, re32), [""]);
  shouldBe(firstMatch(s2, re32), ["aaaa"]);
  shouldBe(firstMatch(s4, re32), ["abab"]);
  shouldBe(firstMatch(s5, re32), ["ab"]);
  shouldBe(firstMatch(s6, re32), [""]);

  // Three possibly empty alternatives with greedy +
  var re33 = new RegExp(r"(?:(?:(?!))|g?|0*\*?)+");
  shouldBe(firstMatch(emptyStr, re33), [""]);
  shouldBe(firstMatch(s1, re33), [""]);
  shouldBe(firstMatch(s7, re33), ["g0"]);

  // first alternative zero length fixed count
  var re34 = new RegExp(r"(?:|a)");
  shouldBe(firstMatch(emptyStr, re34), [""]);
  shouldBe(firstMatch(s1, re34), [""]);
  shouldBe(firstMatch(s2, re34), [""]);
  shouldBe(firstMatch(s3, re34), [""]);
}
