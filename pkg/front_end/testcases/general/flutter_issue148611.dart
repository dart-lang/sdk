// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// For context see https://github.com/flutter/flutter/issues/148611.

class P<T> {
  const P(T t);
}

class A<X> extends P<X> {
  const A.foo(X x) : super(x);
  A(super.x) : assert(const F.foo("foo") == const A.foo("foo"));
}

typedef F<Y> = A<Y>;
