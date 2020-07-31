// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd

import 'package:expect/expect.dart';
import 'generic_function_type_equality_null_safe_lib.dart';

main() {
  // Same functions with different names.
  Expect.equals(fn.runtimeType, fn2.runtimeType);
  Expect.equals(voidToT.runtimeType, voidToS.runtimeType);
  Expect.equals(positionalTToVoid.runtimeType, positionalSToVoid.runtimeType);
  Expect.equals(positionalNullableTToVoid.runtimeType,
      positionalNullableSToVoid.runtimeType);
  Expect.equals(optionalTToVoid.runtimeType, optionalSToVoid.runtimeType);
  Expect.equals(
      optionalNullableTToVoid.runtimeType, optionalNullableSToVoid.runtimeType);
  Expect.equals(namedTToVoid.runtimeType, namedSToVoid.runtimeType);
  Expect.equals(
      namedNullableTToVoid.runtimeType, namedNullableSToVoid.runtimeType);
  Expect.equals(requiredTToVoid.runtimeType, requiredSToVoid.runtimeType);
  Expect.equals(
      requiredNullableTToVoid.runtimeType, requiredNullableSToVoid.runtimeType);

  // Required named arguments are not equal to named arguments.
  Expect.notEquals(namedTToVoid.runtimeType, requiredTToVoid.runtimeType);
  Expect.notEquals(
      namedNullableTToVoid.runtimeType, requiredNullableTToVoid.runtimeType);
}
