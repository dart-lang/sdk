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
  'Test for proper handling of Unicode RegExps and <a href="http://bugzilla.webkit.org/show_bug.cgi?id=7445">bug 7445</a>: Gmail puts wrong subject in replies.'
  );

  // Regex to match Re in various languanges straight from Gmail source
  var I3=new RegExp(r"^\s*(fwd|re|aw|antw|antwort|wg|sv|ang|odp|betreff|betr|transf|reenv\.|reenv|in|res|resp|resp\.|enc|\u8f6c\u53d1|\u56DE\u590D|\u041F\u0435\u0440\u0435\u0441\u043B|\u041E\u0442\u0432\u0435\u0442):\s*(.*)$", caseSensitive: false);

  // Other RegExs from Gmail source
  var Ci=new RegExp(r"\s+");
  var BC=new RegExp(r"^ ");
  var BG=new RegExp(r" $");

  // This function replaces consecutive whitespace with a single space
  // then removes a leading and trailing space if they exist. (From Gmail)
  dynamic Gn(a) {
      return a.replaceAll(Ci, " ").replaceAll(BC, "").replaceAll(BG, "");
  }

  // Strips leading Re or similar (from Gmail source)
  dynamic cy(a) {
      //var b = I3.firstMatch(a);
      var b = I3.firstMatch(a);

      if (b != null) {
          a = b.group(2);
      }

      return Gn(a);
  }

  assertEquals(cy('Re: Moose'), 'Moose');
  assertEquals(cy('\u8f6c\u53d1: Moose'), 'Moose');

  // Test handling of \u2820 (skull and crossbones)
  var sample="sample bm\u2820p cm\\u2820p";

  var inlineRe=new RegExp(r".m\u2820p");
  assertEquals(inlineRe.firstMatch(sample).group(0), 'bm\u2820p');


  // Test handling of \u007c "|"
  var bsample="sample bm\u007cp cm\\u007cp";

  var binlineRe=new RegExp(r".m\u007cp");

  assertEquals(binlineRe.firstMatch(bsample).group(0), 'bm|p');
}
