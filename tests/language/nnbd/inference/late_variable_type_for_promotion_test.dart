// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

/// Test that promotion logic properly understands the type of a late variable.
/// In particular, make sure that CFE late lowering doesn't cause flow analysis
/// to treat the type as nullable when it's non-nullable.

void nonNullableInitializedWithType() {
  late num x = 0;
  x.expectStaticType<Exactly<num>>();
  // Attempting to promote to `int?` should do nothing, since `int?` is not a
  // subtype of `num`.
  if (x is int?) {
    x.expectStaticType<Exactly<num>>();
  }
  // Attempting to promote to `int` should be ok, though.
  if (x is int) {
    x.expectStaticType<Exactly<int>>();
  }
}

void nullableInitializedWithType() {
  late num? x = 0 as num?; // Cast to prevent promotion
  x.expectStaticType<Exactly<num?>>();
  // Attempting to promote to `num` should be ok, since `num` is a subtype of
  // `num?`.
  if (x is num) {
    x.expectStaticType<Exactly<num>>();
  }
  // Attempting to promote to `int?` should be ok too.
  if (x is int?) {
    x.expectStaticType<Exactly<int?>>();
  }
}

void nonNullableInitializedUntyped() {
  late var x = 0 as num;
  x.expectStaticType<Exactly<num>>();
  // Attempting to promote to `int?` should do nothing, since `int?` is not a
  // subtype of `num`.
  if (x is int?) {
    x.expectStaticType<Exactly<num>>();
  }
  // Attempting to promote to `int` should be ok, though.
  if (x is int) {
    x.expectStaticType<Exactly<int>>();
  }
}

void nullableInitializedUntyped() {
  late var x = 0 as num?;
  x.expectStaticType<Exactly<num?>>();
  // Attempting to promote to `num` should be ok, since `num` is a subtype of
  // `num?`.
  if (x is num) {
    x.expectStaticType<Exactly<num>>();
  }
  // Attempting to promote to `int?` should be ok too.
  if (x is int?) {
    x.expectStaticType<Exactly<int?>>();
  }
}

void nonNullableUninitializedWithType() {
  late num x;
  x = 0;
  x.expectStaticType<Exactly<num>>();
  // Attempting to promote to `int?` should do nothing, since `int?` is not a
  // subtype of `num`.
  if (x is int?) {
    x.expectStaticType<Exactly<num>>();
  }
  // Attempting to promote to `int` should be ok, though.
  if (x is int) {
    x.expectStaticType<Exactly<int>>();
  }
}

void nullableUninitializedWithType() {
  late num? x;
  x = 0 as num?; // Cast to prevent promotion
  x.expectStaticType<Exactly<num?>>();
  // Attempting to promote to `num` should be ok, since `num` is a subtype of
  // `num?`.
  if (x is num) {
    x.expectStaticType<Exactly<num>>();
  }
  // Attempting to promote to `int?` should be ok too.
  if (x is int?) {
    x.expectStaticType<Exactly<int?>>();
  }
}

void uninitializedUntyped() {
  late var x;
  x = 0;
  if (false) {
    // Check that the static type of [x] is dynamic:
    Never n = x;
    x = 0;
    x = false;
  }
  // Attempting to promote to `int?` should be ok, since `int?` is a subtype of
  // `dynamic`.
  if (x is int?) {
    x.expectStaticType<Exactly<int?>>();
  }
  // Attempting to promote to `int` should be ok too.
  if (x is int) {
    x.expectStaticType<Exactly<int>>();
  }
}

main() {
  nonNullableInitializedWithType();
  nullableInitializedWithType();
  nonNullableInitializedUntyped();
  nullableInitializedUntyped();
  nonNullableUninitializedWithType();
  nullableUninitializedWithType();
  uninitializedUntyped();
}
