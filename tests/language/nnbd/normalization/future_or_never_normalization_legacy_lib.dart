// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.7

import 'dart:async';

import 'package:expect/expect.dart';

import 'future_or_never_normalization_test.dart';

@pragma('dart2js:noInline')
bool legacyTypeTest<T>(dynamic val) => val is T;

@pragma('dart2js:noInline')
bool legacyFutureOrTypeTest<T>(dynamic val) => val is FutureOr<T>;

void weakTests() {
  Expect.isTrue(typeTest<FutureOr<Never>>(null));
  Expect.isTrue(futureOrTypeTest<Never>(null));
  Expect.isTrue(legacyFutureOrTypeTest<Never>(null));
}
