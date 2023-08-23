// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N void_checks`

import 'dart:async';

void emptyFunctionExpressionReturningFutureOrVoid(FutureOr<void> Function() f) {
  f = () {}; // OK
}

Never fail() { throw 'nope'; }

void m1() async {
  await Future.value(5).then<void>((x) { // OK
    fail();
  });
}

// https://github.com/dart-lang/linter/issues/3172
void capture(FutureOr<void> Function() callback) {}

void m2() {
  capture(() { // OK
    throw "oh no";
  });
}
