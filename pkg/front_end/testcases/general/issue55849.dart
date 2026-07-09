// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {
  const A.foo(X x);
}

typedef F<Y> = A<Y>;

@F.foo("foo")
void bar() {}
