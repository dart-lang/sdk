// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

import "package:expect/expect.dart";

typedef dynamicToDynamic = dynamic Function(dynamic);

typedef voidToT = T Function<T>();

dynamic dynamicNull = null;

cast<T>(dynamic value) => value as T;

bool allowsArgument(T Function<T>() fn) => true;

main() {
  // In strong mode Null is not a subtype of function types.
  Expect.throwsTypeError(() => dynamicNull as Function);
  Expect.throwsTypeError(() => dynamicNull as dynamicToDynamic);
  Expect.throwsTypeError(() => cast<dynamic Function(dynamic)>(dynamicNull));
  Expect.throwsTypeError(() => dynamicNull as voidToT);
  Expect.throwsTypeError(() => allowsArgument(dynamicNull));
}
