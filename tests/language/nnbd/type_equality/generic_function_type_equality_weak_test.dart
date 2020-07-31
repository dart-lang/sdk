// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Can't run in strong mode since it contains a legacy library.
// Requirements=nnbd-weak

import 'package:expect/expect.dart';
import 'generic_function_type_equality_legacy_lib.dart' as legacy;
import 'generic_function_type_equality_null_safe_lib.dart';

main() {
  // Default type bounds are not equal. T extends Object? vs T extends Object*
  Expect.notEquals(fn.runtimeType, legacy.fn.runtimeType);
  Expect.notEquals(voidToT.runtimeType, legacy.voidToR.runtimeType);
  Expect.notEquals(
      positionalTToVoid.runtimeType, legacy.positionalRToVoid.runtimeType);
  Expect.notEquals(
      optionalTToVoid.runtimeType, legacy.optionalRToVoid.runtimeType);
  Expect.notEquals(namedTToVoid.runtimeType, legacy.namedRToVoid.runtimeType);

  // Type arguments in methods tear-offs from null safe libraries become Object?
  // and Object* from legacy libraries and are not equal.
  Expect.notEquals(A().fn.runtimeType, legacy.A().fn.runtimeType);
  Expect.notEquals(A().fn.runtimeType, legacy.rawAFnTearoff.runtimeType);
  Expect.notEquals(A<C>().fn.runtimeType, legacy.A<C>().fn.runtimeType);

  // Same signatures but one is from a legacy library.
  Expect.equals(positionalTToVoidWithBound.runtimeType,
      legacy.positionalTToVoidWithBound.runtimeType);
  Expect.equals(optionalTToVoidWithBound.runtimeType,
      legacy.optionalTToVoidWithBound.runtimeType);
  Expect.equals(namedTToVoidWithBound.runtimeType,
      legacy.namedTToVoidWithBound.runtimeType);

  // Required named arguments are not equal to named arguments.
  Expect.notEquals(
      requiredTToVoid.runtimeType, legacy.namedRToVoid.runtimeType);
}
