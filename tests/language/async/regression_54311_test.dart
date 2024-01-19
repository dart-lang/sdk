// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that futureValueType(FutureOr<Object>) = Object.
//
// This is a special case because NORM(FutureOr<Object>) = Object,
// and futureValueType(Object) = Object?, so futureValueType cannot be
// applied to a normalized type.
//
// Regression test for https://github.com/dart-lang/sdk/issues/54311.

import 'dart:async';

import "package:expect/expect.dart";

FutureOr<Object> fn1() async {
  return Future<Object>.value(42);
}

FutureOr<Object> fn2() async => 42;

void main() async {
  final value1 = await fn1();
  Expect.equals(42, value1);

  final value2 = await fn2();
  Expect.equals(42, value2);
}
