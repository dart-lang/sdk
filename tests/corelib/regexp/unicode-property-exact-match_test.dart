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
  assertThrows(() => RegExp("\\p{In CJK}", unicode: true));
  assertThrows(() => RegExp("\\p{InCJKUnifiedIdeographs}", unicode: true));
  assertThrows(() => RegExp("\\p{InCJK}", unicode: true));
  assertThrows(() => RegExp("\\p{InCJK_Unified_Ideographs}", unicode: true));

  assertThrows(() => RegExp("\\p{InCyrillic_Sup}", unicode: true));
  assertThrows(() => RegExp("\\p{InCyrillic_Supplement}", unicode: true));
  assertThrows(() => RegExp("\\p{InCyrillic_Supplementary}", unicode: true));
  assertThrows(() => RegExp("\\p{InCyrillicSupplementary}", unicode: true));
  assertThrows(() => RegExp("\\p{InCyrillic_supplementary}", unicode: true));

  assertDoesNotThrow(() => RegExp("\\p{C}", unicode: true));
  assertDoesNotThrow(() => RegExp("\\p{Other}", unicode: true));
  assertDoesNotThrow(() => RegExp("\\p{Cc}", unicode: true));
  assertDoesNotThrow(() => RegExp("\\p{Control}", unicode: true));
  assertDoesNotThrow(() => RegExp("\\p{cntrl}", unicode: true));
  assertDoesNotThrow(() => RegExp("\\p{M}", unicode: true));
  assertDoesNotThrow(() => RegExp("\\p{Mark}", unicode: true));
  assertDoesNotThrow(() => RegExp("\\p{Combining_Mark}", unicode: true));
  assertThrows(() => RegExp("\\p{Combining Mark}", unicode: true));

  assertDoesNotThrow(() => RegExp("\\p{Script=Copt}", unicode: true));
  assertThrows(() => RegExp("\\p{Coptic}", unicode: true));
  assertThrows(() => RegExp("\\p{Qaac}", unicode: true));
  assertThrows(() => RegExp("\\p{Egyp}", unicode: true));
  assertDoesNotThrow(
      () => RegExp("\\p{Script=Egyptian_Hieroglyphs}", unicode: true));
  assertThrows(() => RegExp("\\p{EgyptianHieroglyphs}", unicode: true));

  assertThrows(() => RegExp("\\p{BidiClass=LeftToRight}", unicode: true));
  assertThrows(() => RegExp("\\p{BidiC=LeftToRight}", unicode: true));
  assertThrows(() => RegExp("\\p{bidi_c=Left_To_Right}", unicode: true));

  assertThrows(() => RegExp("\\p{Block=CJK}", unicode: true));
  assertThrows(() => RegExp("\\p{Block = CJK}", unicode: true));
  assertThrows(() => RegExp("\\p{Block=cjk}", unicode: true));
  assertThrows(() => RegExp("\\p{BLK=CJK}", unicode: true));
}
