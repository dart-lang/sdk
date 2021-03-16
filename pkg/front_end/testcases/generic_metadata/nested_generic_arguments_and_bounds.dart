// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {}

A<Function<Y extends Function<Z>(Z)>(Y)> foo() => throw 42;

typedef F<U> = Function<V extends U>(V);

A<F<Function<W>(W)>> bar() => throw 42;

main() {}
