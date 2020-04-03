// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

import 'package:expect/expect.dart';

import 'function_type_bounds_null_safe_lib.dart';

main() {
  // void fn<T extends Object>() is void Function<T extends Object?>()
  // Should fail with strong checking because Object and Object? should be
  // treated as type bounds that are not equivalent.
  Expect.isFalse(fnWithNonNullObjectBound is fnTypeWithNullableObjectBound);

  // void fn<T extends Null>() is void Function<T extends Never>()
  // Should fail with strong checking because because Null and Never are treated
  // as distinct.
  Expect.isFalse(fnWithNullBound is fnTypeWithNeverBound);
}
