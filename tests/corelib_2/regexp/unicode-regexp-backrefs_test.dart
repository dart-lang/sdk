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

String replace(String string) {
  return string
      .replaceAll("L", "\ud800")
      .replaceAll("l", "\ud801")
      .replaceAll("T", "\udc00")
      .replaceAll(".", "[^]");
}

void test(List<String> expectation, String regexp_source, String subject) {
  if (expectation != null) expectation = expectation.map(replace).toList();
  subject = replace(subject);
  regexp_source = replace(regexp_source);
  shouldBe(new RegExp(regexp_source, unicode: true).firstMatch(subject),
      expectation);
}

void main() {
  // Back reference does not end in the middle of a surrogate pair.
  test(null, "(L)\\1", "LLT");
  test(["LLTLl", "L", "l"], "(L).*\\1(.)", "LLTLl");
  test(null, "(aL).*\\1", "aLaLT");
  test(["aLaLTaLl", "aL", "l"], "(aL).*\\1(.)", "aLaLTaLl");

  var s = "TabcLxLTabcLxTabcLTyTabcLz";
  test([s, "TabcL", "z"], "([^x]+).*\\1(.)", s);

  // Back reference does not start in the middle of a surrogate pair.
  test(["TLTabTc", "T", "c"], "(T).*\\1(.)", "TLTabTc");

  // Lookbehinds.
  test(null, "(?<=\\1(T)x)", "LTTx");
  test(["", "b", "T"], "(?<=(.)\\2.*(T)x)", "bTaLTTx");
  test(null, "(?<=\\1.*(L)x)", "LTLx");
  test(["", "b", "L"], "(?<=(.)\\2.*(L)x)", "bLaLTLx");

  test(null, "([^x]+)x*\\1", "LxLT");
  test(null, "([^x]+)x*\\1", "TxLT");
  test(null, "([^x]+)x*\\1", "LTxL");
  test(null, "([^x]+)x*\\1", "LTxT");
  test(null, "([^x]+)x*\\1", "xLxLT");
  test(null, "([^x]+)x*\\1", "xTxLT");
  test(null, "([^x]+)x*\\1", "xLTxL");
  test(null, "([^x]+)x*\\1", "xLTxT");
  test(null, "([^x]+)x*\\1", "xxxLxxLTxx");
  test(null, "([^x]+)x*\\1", "xxxTxxLTxx");
  test(null, "([^x]+)x*\\1", "xxxLTxxLxx");
  test(null, "([^x]+)x*\\1", "xxxLTxxTxx");
  test(["LTTxxLTT", "LTT"], "([^x]+)x*\\1", "xxxLTTxxLTTxx");
}
