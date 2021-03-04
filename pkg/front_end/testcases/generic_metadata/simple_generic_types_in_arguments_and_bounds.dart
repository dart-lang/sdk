// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {}

A<Function<Y>(Y)> foo(A<Function<Y>(Y)> x) => throw 42;

class B extends A<Function<Y>(Y)> {}

class C<Z extends Function<Y>(Y)> {}

bar<V extends Function<Y>(Y)>() => throw 42;

main() {}
