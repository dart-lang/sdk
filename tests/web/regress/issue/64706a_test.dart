// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for https://dartbug.com/64706
//
// Synchronous reproductions where SsaPhiConditioning hoists a constant null
// into the HTry block. Because code generation skips the HTry block, the
// hoisted temporary variable is either never declared or retains a stale value
// from an earlier expression before the try block.

import 'package:expect/expect.dart';

void mayThrow(int n) {
  if (DateTime.now().millisecondsSinceEpoch == n) throw 'boom';
}

@pragma('dart2js:never-inline')
String testUndeclared(int a) {
  String? code;
  mayThrow(a + 1);
  try {
    mayThrow(a + 1);
  } on String catch (e) {
    code = e;
  }
  if (code != null) {
    return 'FAILED: ${(() => code)()}';
  } else {
    return 'ok';
  }
}

@pragma('dart2js:never-inline')
String testStale(int a) {
  String? code;
  mayThrow(a + 1);
  mayThrow(a + 1);
  try {
    mayThrow(0);
  } on String catch (e) {
    code = e;
  }
  if (code != null) {
    return 'FAILED: ${(() => code)()}';
  } else {
    return 'ok';
  }
}

void main() {
  Expect.equals('ok', testStale(1));
  Expect.equals('ok', testUndeclared(1));
}
