// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

import 'package:expect/expect.dart';

import 'function_type_bounds_null_safe_lib.dart';

main() {
  // void fn<T extends Object>() is void Function<T extends Object?>()
  // Should pass with weak checking because when the nullability information on
  // Object and Object? are erased the type bounds are equivalent.
  Expect.isTrue(fnWithNonNullObjectBound is fnTypeWithNullableObjectBound);
  const test1 = fnWithNonNullObjectBound is fnTypeWithNullableObjectBound;
  Expect.isTrue(test1);

  // void fn<T extends Null>() is void Function<T extends Never>()
  // Should pass with weak checking because because Null becomes equivalent to
  // the bottom type.
  Expect.isTrue(fnWithNullBound is fnTypeWithNeverBound);
  const test2 = fnWithNullBound is fnTypeWithNeverBound;
  Expect.isTrue(test2);
}
