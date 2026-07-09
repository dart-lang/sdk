// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks the nullability of the result of the type substitution
// performed as a part of type inference, including its fall-back mechanism
// which is instantiate-to-bounds.

foo<T extends Object?, S extends List<T>>(T t) => null;

bar<T extends Object?, S extends List<T?>>(T t) => null;

baz(int? x, int y) {
  foo(x);
  bar(y);
}

class A<T extends Object?, S extends Object> {
  hest<X extends T, Y extends List<X>, Z extends List<X?>>() => null;
  fisk<X extends S, Y extends List<X>, Z extends List<X?>>() => null;
  mus<X extends Object?, Y extends List<X>, Z extends List<X?>>() => null;
}

main() {}
