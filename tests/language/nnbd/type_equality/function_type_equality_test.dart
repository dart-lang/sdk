// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'function_type_equality_nnbd_lib.dart';

main() {
  // Same functions with different names.
  Expect.equals(fn.runtimeType, fn2.runtimeType);
  Expect.equals(voidToInt.runtimeType, voidToInt2.runtimeType);
  Expect.equals(voidToNullableInt.runtimeType, voidToNullableInt2.runtimeType);
  Expect.equals(positionalNullableIntToVoid.runtimeType,
      positionalNullableIntToVoid2.runtimeType);
  Expect.equals(optionalIntToVoid.runtimeType, optionalIntToVoid2.runtimeType);
  Expect.equals(optionalNullableIntToVoid.runtimeType,
      optionalNullableIntToVoid2.runtimeType);
  Expect.equals(namedIntToVoid.runtimeType, namedIntToVoid2.runtimeType);
  Expect.equals(
      namedNullableIntToVoid.runtimeType, namedNullableIntToVoid2.runtimeType);
  Expect.equals(requiredIntToVoid.runtimeType, requiredIntToVoid2.runtimeType);
  Expect.equals(requiredNullableIntToVoid.runtimeType,
      requiredNullableIntToVoid2.runtimeType);

  // Required named arguments are not equal to named arguments.
  Expect.notEquals(requiredIntToVoid.runtimeType, namedIntToVoid.runtimeType);
}
