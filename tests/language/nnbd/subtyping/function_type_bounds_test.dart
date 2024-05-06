// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'function_type_bounds_null_safe_lib.dart';

main() {
  // void fn<T extends Object>() is void Function<T extends Object>()
  Expect.isTrue(fnWithNonNullObjectBound is fnTypeWithNonNullObjectBound);

  // void fn<T extends int>() is void Function<T extends int>()
  Expect.isTrue(fnWithNonNullIntBound is fnTypeWithNonNullIntBound);

  // void fn<T extends Object?>() is void Function<T extends Object?>()
  Expect.isTrue(fnWithNullableObjectBound is fnTypeWithNullableObjectBound);
  // void fn<T extends int?>() is void Function<T extends int?>()
  Expect.isTrue(fnWithNullableIntBound is fnTypeWithNullableIntBound);

  // void fn<T extends Object?>() is! void Function<T extends Object>()
  // (except when using unsound null safety)
  Expect.equals(hasUnsoundNullSafety,
      fnWithNullableObjectBound is fnTypeWithNonNullObjectBound);
  // void fn<T extends Object>() is! void Function<T extends Object?>()
  // (except when using unsound null safety)
  Expect.equals(hasUnsoundNullSafety,
      fnWithNonNullObjectBound is fnTypeWithNullableObjectBound);
}
