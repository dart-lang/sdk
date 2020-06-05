// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Can't run in strong mode since it contains a legacy library.
// Requirements=nnbd-weak

import 'package:expect/expect.dart';

import 'function_type_equality_nnbd_lib.dart';
import 'function_type_equality_legacy_lib.dart' as legacy;

main() {
  // Same signatures but one is from a legacy library.
  Expect.equals(fn.runtimeType, legacy.fn.runtimeType);
  Expect.equals(voidToInt.runtimeType, legacy.voidToInt.runtimeType);
  Expect.equals(
      positionalIntToVoid.runtimeType, legacy.positionalIntToVoid.runtimeType);
  Expect.equals(
      optionalIntToVoid.runtimeType, legacy.optionalIntToVoid.runtimeType);
  Expect.equals(namedIntToVoid.runtimeType, legacy.namedIntToVoid.runtimeType);
  Expect.equals(gn.runtimeType, legacy.gn.runtimeType);
  Expect.equals(hn.runtimeType, legacy.hn.runtimeType);

  // Nullable types are not equal to legacy types.
  Expect.notEquals(positionalNullableIntToVoid.runtimeType,
      legacy.positionalIntToVoid.runtimeType);
  Expect.notEquals(optionalNullableIntToVoid.runtimeType,
      legacy.optionalIntToVoid.runtimeType);
  Expect.notEquals(
      namedNullableIntToVoid.runtimeType, legacy.namedIntToVoid.runtimeType);
  Expect.notEquals(voidToNullableInt.runtimeType, legacy.voidToInt.runtimeType);

  // Required named arguments are not equal to named arguments.
  Expect.notEquals(
      requiredIntToVoid.runtimeType, legacy.namedIntToVoid.runtimeType);
}
