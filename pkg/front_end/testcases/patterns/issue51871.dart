// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T id<T>(T t) => t;

typedef IntFn = int Function(int);
typedef TFn = T Function<T>(T);

abstract class CompareBase {
  operator<(IntFn f);
}

class Compare extends CompareBase {
  @override
  operator<(Object f) => f is TFn;
}

test1(CompareBase x) {
  const c = id;
  if (x case < c) {
    throw '"<" should receive instantiation, not generic function.';
  } else {
    // OK.
  }
}

main() {
  test1(new Compare());
}
