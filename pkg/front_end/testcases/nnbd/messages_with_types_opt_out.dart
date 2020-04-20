// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

import 'messages_with_types_opt_in.dart';

class SuperOut {
  String nullableSame() => "foo";
  String nonNullableSame() => "bar";
  int nullableBad<T>(T t) => 1;
  int nonNullableBad<T>(T t) => 2;
}

class SubOutOut extends SuperOut {
  String nullableSame() => "foo";
  String nonNullableSame() => "bar";
  T nullableBad<T>(T t) => null;
  T nonNullableBad<T>(T t) => t;
}

class SubInOut extends SuperIn {
  String nullableSame() => "foo";
  String nonNullableSame() => "bar";
  T nullableBad<T>(T t) => null;
  T nonNullableBad<T>(T t) => t;
}

String legacyVar = "legacy";

testOptOut() {
  nullableVar = nonNullableVar;
  nonNullableVar = nullableVar;
  legacyVar = nullableVar;
  nullableVar = legacyVar;
  nonNullableVar = legacyVar;
  legacyVar = nonNullableVar;
}
