// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F = Function<Y>(Y);

class A<X> {}

A<F> foo(A<F> x) => throw 42;

class B extends A<F> {}

class C<Z extends F> {}

bar<V extends F>() => throw 42;

main() {}
