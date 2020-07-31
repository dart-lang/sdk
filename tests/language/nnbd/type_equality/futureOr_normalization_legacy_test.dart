// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opt out of Null Safety:
// @dart = 2.6

// Can't run in strong mode since it contains a legacy library.
// Requirements=nnbd-weak

import 'dart:async';

import 'package:expect/expect.dart';

import 'futureOr_normalization_null_safe_lib.dart' as nullSafe;

Type extractType<T>() => T;
Type extractFutureOrType<T>() => _<FutureOr<T>>().runtimeType;
Type embedFutureOrType<T>() => nullSafe.Embed<FutureOr<T>>().runtimeType;

/// A class that should be ignored but it used embed the type signatures
/// actually being tested.
class _<T> {}

main() {
  // FutureOr types are normalized when they appear explicitly in the source.
  Expect.equals(dynamic, extractType<FutureOr>());
  Expect.equals(dynamic, extractType<FutureOr<dynamic>>());
  Expect.equals(extractType<Object>(), extractType<FutureOr<Object>>());
  Expect.equals(extractType<void>(), extractType<FutureOr<void>>());
  Expect.equals(nullSafe.embeddedNullableFutureOfNull,
      extractType<nullSafe.Embed<FutureOr<Null>>>());

  // FutureOr types are normalized when they are created at runtime.
  Expect.equals(extractType<_<dynamic>>(), extractFutureOrType());
  Expect.equals(extractType<_<dynamic>>(), extractFutureOrType<dynamic>());
  Expect.equals(extractType<_<Object>>(), extractFutureOrType<Object>());
  Expect.equals(extractType<_<void>>(), extractFutureOrType<void>());
  Expect.equals(
      nullSafe.embeddedNullableFutureOfNull, embedFutureOrType<Null>());
}
