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

void main() {
  // Testing handling of paired and non-paired surrogates in unicode mode
  var r = new RegExp(r".", unicode: true);

  var m = r.matchAsPrefix("\ud800\udc00\ud801\udc01");
  shouldBe(m, ["\ud800\udc00"]);
  assertEquals(m.end, 2);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01", 1);
  shouldBe(m, ["\ud800\udc00"]);
  assertEquals(m.end, 2);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01", 2);
  shouldBe(m, ["\ud801\udc01"]);
  assertEquals(m.end, 4);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01", 3);
  shouldBe(m, ["\ud801\udc01"]);
  assertEquals(m.end, 4);

  assertNull(r.matchAsPrefix("\ud800\udc00\ud801\udc01", 4));

  m = r.matchAsPrefix("\ud800\udc00\ud801\ud802", 3);
  shouldBe(m, ["\ud802"]);

  assertNull(r.matchAsPrefix("\ud800\udc00\ud801\ud802", 4));

  // Testing handling of paired and non-paired surrogates in non-unicode mode
  r = new RegExp(r".");

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01");
  shouldBe(m, ["\ud800"]);
  assertEquals(m.end, 1);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01", 1);
  shouldBe(m, ["\udc00"]);
  assertEquals(m.end, 2);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01", 2);
  shouldBe(m, ["\ud801"]);
  assertEquals(m.end, 3);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01", 3);
  shouldBe(m, ["\udc01"]);
  assertEquals(m.end, 4);

  assertNull(r.matchAsPrefix("\ud800\udc00\ud801\udc01", 4));

  // Testing same with start anchor, unicode mode.
  r = new RegExp("^.", unicode: true);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01");
  shouldBe(m, ["\ud800\udc00"]);
  assertEquals(2, m.end);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01", 1);
  shouldBe(m, ["\ud800\udc00"]);
  assertEquals(2, m.end);

  assertNull(r.matchAsPrefix("\ud800\udc00\ud801\udc01", 2));
  assertNull(r.matchAsPrefix("\ud800\udc00\ud801\udc01", 3));
  assertNull(r.matchAsPrefix("\ud800\udc00\ud801\udc01", 4));

  // Testing same with start anchor, non-unicode mode.
  r = new RegExp("^.");
  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01");
  shouldBe(m, ["\ud800"]);
  assertEquals(1, m.end);

  assertNull(r.matchAsPrefix("\ud800\udc00\ud801\udc01", 1));
  assertNull(r.matchAsPrefix("\ud800\udc00\ud801\udc01", 2));
  assertNull(r.matchAsPrefix("\ud800\udc00\ud801\udc01", 3));
  assertNull(r.matchAsPrefix("\ud800\udc00\ud801\udc01", 4));

  // Now with both anchored and not as alternatives (with the anchored
  // version as a captured group), unicode mode.
  r = new RegExp(r"(?:(^.)|.)", unicode: true);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01");
  shouldBe(m, ["\ud800\udc00", "\ud800\udc00"]);
  assertEquals(m.end, 2);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01", 1);
  shouldBe(m, ["\ud800\udc00", "\ud800\udc00"]);
  assertEquals(m.end, 2);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01", 2);
  shouldBe(m, ["\ud801\udc01", null]);
  assertEquals(m.end, 4);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01", 3);
  shouldBe(m, ["\ud801\udc01", null]);
  assertEquals(m.end, 4);

  assertNull(r.matchAsPrefix("\ud800\udc00\ud801\udc01", 4));

  m = r.matchAsPrefix("\ud800\udc00\ud801\ud802", 3);
  shouldBe(m, ["\ud802", null]);

  assertNull(r.matchAsPrefix("\ud800\udc00\ud801\ud802", 4));

  // Now with both anchored and not as alternatives (with the anchored
  // version as a captured group), non-unicode mode.
  r = new RegExp(r"(?:(^.)|.)");

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01");
  shouldBe(m, ["\ud800", "\ud800"]);
  assertEquals(m.end, 1);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01", 1);
  shouldBe(m, ["\udc00", null]);
  assertEquals(m.end, 2);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01", 2);
  shouldBe(m, ["\ud801", null]);
  assertEquals(m.end, 3);

  m = r.matchAsPrefix("\ud800\udc00\ud801\udc01", 3);
  shouldBe(m, ["\udc01", null]);
  assertEquals(m.end, 4);

  assertNull(r.matchAsPrefix("\ud800\udc00\ud801\udc01", 4));
}
