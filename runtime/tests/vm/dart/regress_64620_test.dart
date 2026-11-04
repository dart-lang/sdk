// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for https://github.com/dart-lang/sdk/issues/64620.
//
// Failing `as FutureOr<T>` check on a Smi used to crash in the
// Subtype2TestCache stub after a heap object passed the same check.

import 'dart:async';

import 'package:expect/expect.dart';

@pragma('vm:never-inline')
void check(Object? x) {
  x as FutureOr<String>;
}

void main() {
  check('a');
  Expect.throwsTypeError(() => check(42));
  check('b');
  Expect.throwsTypeError(() => check(43));
}
