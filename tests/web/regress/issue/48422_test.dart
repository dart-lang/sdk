// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  testTryFinally();
  testTryCatchFinally();
}

void testTryFinally() {
  callback(Map<String, dynamic> m) {
    Expect.isNull(m['foo']);
  }

  var val;
  try {
    try {
      val = <String, dynamic>{};
    } catch (_) {
      val = {}.cast<String, dynamic>();
    }
    // This `return` means we consider the `try` block to abort. Nevertheless,
    // the results of its inference must flow to the `finally`.
    return;
  } finally {
    callback(val);
  }
}

void testTryCatchFinally() {
  callback(Map<String, dynamic> m) {
    Expect.isNull(m['foo']);
  }

  var val;
  try {
    try {
      val = <String, dynamic>{};
    } catch (_) {
      val = {}.cast<String, dynamic>();
    }
    // This `return` means we consider the `try` block to abort. Nevertheless,
    // the results of its inference must flow to the `finally`.
    return;
  } catch (_) {
  } finally {
    callback(val);
  }
}
