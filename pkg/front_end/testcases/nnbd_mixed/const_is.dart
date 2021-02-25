// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test derived from language/nnbd/subtyping/function_type_bounds_weak_test

import 'const_is_lib.dart';

main() {
  // void fn<T extends Object>() is void Function<T extends Object?>()
  // Should pass with weak checking because when the nullability information on
  // Object and Object? are erased the type bounds are equivalent.
  expect(true, fnWithNonNullObjectBound is fnTypeWithNullableObjectBound);
  const test1 = fnWithNonNullObjectBound is fnTypeWithNullableObjectBound;
  expect(true, test1);

  // void fn<T extends Null>() is void Function<T extends Never>()
  // Should pass with weak checking because because Null becomes equivalent to
  // the bottom type.
  expect(true, fnWithNullBound is fnTypeWithNeverBound);
  const test2 = fnWithNullBound is fnTypeWithNeverBound;
  expect(true, test2);
}

expect(expected, actual) {
  if (expected != actual) throw "Expected $expected, actual $actual";
}
