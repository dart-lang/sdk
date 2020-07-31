// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

import "package:expect/expect.dart";

typedef dynamicToDynamic = dynamic Function(dynamic);

typedef voidToT = T Function<T>();

dynamic dynamicNull = null;

dynamic cast<T>(dynamic value) => value as T;

bool allowsArgument(T Function<T>() fn) => true;

main() {
  // In weak mode Null should be allowed as a subtype of function types.
  Expect.equals(null, dynamicNull as Function);
  Expect.equals(null, dynamicNull as dynamicToDynamic);
  Expect.equals(null, cast<dynamic Function(dynamic)>(dynamicNull));
  Expect.equals(null, dynamicNull as voidToT);
  Expect.equals(true, allowsArgument(dynamicNull));
}
