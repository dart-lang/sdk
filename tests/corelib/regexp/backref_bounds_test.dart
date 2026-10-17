// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests forward backreference boundary matching and rejection.
//
// Note: Reproducing the signed 32-bit integer overflow in the interpreter
// forward backreference handlers requires a subject string >= 1 GiB
// (current + len >= 2^31), which cannot be run in the automated test suite
// due to memory constraints on CI bots. The overflow arithmetic is verified
// by the C++ unit test RegExp_RangeInBounds in runtime/vm/regexp/regexp_test.cc
// and standalone PoC validation. This test provides functional regression
// coverage ensuring that standard backreference matching, non-matching,
// and empty capture handling remain correct.

import 'package:expect/expect.dart';

void main() {
  // Test basic backreference matching.
  final r = RegExp(r'^(a+)\1$');
  Expect.isTrue(r.hasMatch('aaaa'));
  Expect.isFalse(r.hasMatch('aaa'));

  // Test non-matching forward backreference does not fault.
  final r2 = RegExp(r'(\w+)\1');
  Expect.isNull(r2.firstMatch('abcdef'));

  // Test empty capture backreference.
  final r3 = RegExp(r'()\1');
  Expect.isNotNull(r3.firstMatch('abc'));
}
