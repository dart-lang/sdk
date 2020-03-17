// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:expect/expect.dart';

import 'futureOr_normalization_null_safe_lib.dart';
import 'futureOr_normalization_legacy_lib.dart' as legacy;

class A {}

Type extractFutureOrType<T>() => Embed<FutureOr<T>>().runtimeType;
Type embedNullableFutureOrType<T>() => Embed<FutureOr<T>?>().runtimeType;

main() {
  // FutureOr types are normalized when they appear explicitly in the source.
  Expect.identical(dynamic, extractType<FutureOr>());
  Expect.identical(dynamic, extractType<FutureOr<dynamic>>());
  Expect.identical(Object, extractType<FutureOr<Object>>());
  Expect.identical(extractType<Object?>(), extractType<FutureOr<Object>?>());
  Expect.identical(extractType<Object?>(), extractType<FutureOr<Object?>>());
  Expect.identical(extractType<void>(), extractType<FutureOr<void>>());
  Expect.identical(
      extractType<Future<Never>>(), extractType<FutureOr<Never>>());
  Expect.identical(extractType<Future<Null>?>(), extractType<FutureOr<Null>>());
  Expect.identical(
      extractType<FutureOr<int?>>(), extractType<FutureOr<int?>?>());
  Expect.identical(extractType<FutureOr<A?>>(), extractType<FutureOr<A?>?>());

  // FutureOr types are normalized when they are composed at runtime.
  Expect.identical(extractType<Embed<dynamic>>(), extractFutureOrType());
  Expect.identical(
      extractType<Embed<dynamic>>(), extractFutureOrType<dynamic>());
  Expect.identical(extractType<Embed<Object>>(), extractFutureOrType<Object>());
  Expect.identical(
      extractType<Embed<Object?>>(), embedNullableFutureOrType<Object>());
  Expect.identical(
      extractType<Embed<Object?>>(), extractFutureOrType<Object?>());
  Expect.identical(extractType<Embed<void>>(), extractFutureOrType<void>());
  Expect.identical(
      extractType<Embed<Future<Never>>>(), extractFutureOrType<Never>());
  Expect.identical(
      extractType<Embed<Future<Null>?>>(), extractFutureOrType<Null>());
  Expect.identical(
      extractType<Embed<FutureOr<int?>>>(), embedNullableFutureOrType<int?>());
  Expect.identical(
      extractType<Embed<FutureOr<A?>>>(), embedNullableFutureOrType<A?>());

  // Object* == FutureOr<Object*>
  Expect.identical(legacy.object, legacy.nonNullableFutureOrOfLegacyObject());
}
