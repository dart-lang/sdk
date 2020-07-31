// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'messages_with_types_opt_out.dart';

class SuperIn {
  String? nullableSame() => "foo";
  String nonNullableSame() => "bar";
  int? nullableBad<T>(T t) => 1;
  int nonNullableBad<T>(T t) => 2;
}

class SubInIn extends SuperIn {
  String? nullableSame() => "foo";
  String nonNullableSame() => "bar";
  T? nullableBad<T>(T t) => null;
  T nonNullableBad<T>(T t) => t;
}

class SubOutIn extends SuperOut {
  String? nullableSame() => "foo";
  String nonNullableSame() => "bar";
  T? nullableBad<T>(T t) => null;
  T nonNullableBad<T>(T t) => t;
}

int Function()? nullableVar = () => 3;
double nonNullableVar = 4.0;

testOptIn() {
  nullableVar = nonNullableVar;
  nonNullableVar = nullableVar;
  legacyVar = nullableVar;
  nullableVar = legacyVar;
  nonNullableVar = legacyVar;
  legacyVar = nonNullableVar;
}
