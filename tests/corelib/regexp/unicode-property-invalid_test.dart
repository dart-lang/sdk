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
  assertThrows(() => RegExp("\p{Block=ASCII}+", unicode: true));
  assertThrows(() => RegExp("\p{Block=ASCII}+", unicode: true));
  assertThrows(() => RegExp("\p{Block=Basic_Latin}+", unicode: true));
  assertThrows(() => RegExp("\p{Block=Basic_Latin}+", unicode: true));

  assertThrows(() => RegExp("\p{blk=CJK}+", unicode: true));
  assertThrows(() => RegExp("\p{blk=CJK_Unified_Ideographs}+", unicode: true));
  assertThrows(() => RegExp("\p{blk=CJK}+", unicode: true));
  assertThrows(() => RegExp("\p{blk=CJK_Unified_Ideographs}+", unicode: true));

  assertThrows(() => RegExp("\p{Block=ASCII}+", unicode: true));
  assertThrows(() => RegExp("\p{Block=ASCII}+", unicode: true));
  assertThrows(() => RegExp("\p{Block=Basic_Latin}+", unicode: true));
  assertThrows(() => RegExp("\p{Block=Basic_Latin}+", unicode: true));

  assertThrows(() => RegExp("\p{NFKD_Quick_Check=Y}+", unicode: true));
  assertThrows(() => RegExp("\p{NFKD_QC=Yes}+", unicode: true));

  assertThrows(() => RegExp("\p{Numeric_Type=Decimal}+", unicode: true));
  assertThrows(() => RegExp("\p{nt=De}+", unicode: true));

  assertThrows(() => RegExp("\p{Bidi_Class=Arabic_Letter}+", unicode: true));
  assertThrows(() => RegExp("\p{Bidi_Class=AN}+", unicode: true));

  assertThrows(() => RegExp("\p{ccc=OV}+", unicode: true));

  assertThrows(() => RegExp("\p{Sentence_Break=Format}+", unicode: true));

  assertThrows(() => RegExp("\\p{In}", unicode: true));
  assertThrows(() => RegExp("\\pI", unicode: true));
  assertThrows(() => RegExp("\\p{I}", unicode: true));
  assertThrows(() => RegExp("\\p{CJK}", unicode: true));

  assertThrows(() => RegExp("\\p{}", unicode: true));
}
