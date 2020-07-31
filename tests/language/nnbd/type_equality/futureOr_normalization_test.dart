// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

// Requirements=nnbd

import 'package:expect/expect.dart';

import 'futureOr_normalization_null_safe_lib.dart';

class A {}

Type extractFutureOrType<T>() => Embed<FutureOr<T>>().runtimeType;
Type embedNullableFutureOrType<T>() => Embed<FutureOr<T>?>().runtimeType;

main() {
  // FutureOr types are normalized when they appear explicitly in the source.
  Expect.equals(dynamic, extractType<FutureOr>());
  Expect.equals(dynamic, extractType<FutureOr<dynamic>>());
  Expect.equals(Object, extractType<FutureOr<Object>>());
  Expect.equals(extractType<Object?>(), extractType<FutureOr<Object>?>());
  Expect.equals(extractType<Object?>(), extractType<FutureOr<Object?>>());
  Expect.equals(extractType<void>(), extractType<FutureOr<void>>());
  Expect.equals(extractType<Future<Never>>(), extractType<FutureOr<Never>>());
  Expect.equals(extractType<Future<Null>?>(), extractType<FutureOr<Null>>());
  Expect.equals(extractType<FutureOr<int?>>(), extractType<FutureOr<int?>?>());
  Expect.equals(extractType<FutureOr<A?>>(), extractType<FutureOr<A?>?>());

  // FutureOr types are normalized when they are composed at runtime.
  Expect.equals(extractType<Embed<dynamic>>(), extractFutureOrType());
  Expect.equals(extractType<Embed<dynamic>>(), extractFutureOrType<dynamic>());
  Expect.equals(extractType<Embed<Object>>(), extractFutureOrType<Object>());
  Expect.equals(
      extractType<Embed<Object?>>(), embedNullableFutureOrType<Object>());
  Expect.equals(extractType<Embed<Object?>>(), extractFutureOrType<Object?>());
  Expect.equals(extractType<Embed<void>>(), extractFutureOrType<void>());
  Expect.equals(
      extractType<Embed<Future<Never>>>(), extractFutureOrType<Never>());
  Expect.equals(
      extractType<Embed<Future<Null>?>>(), extractFutureOrType<Null>());
  Expect.equals(
      extractType<Embed<FutureOr<int?>>>(), embedNullableFutureOrType<int?>());
  Expect.equals(
      extractType<Embed<FutureOr<A?>>>(), embedNullableFutureOrType<A?>());
}
