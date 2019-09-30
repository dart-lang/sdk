// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks the nullability of the result of the type substitution
// performed as a part of type inference.

foo<T extends Object?, S extends List<T>>(T t) => null;

bar<T extends Object?, S extends List<T?>>(T t) => null;

baz(int? x, int y) {
  foo(x);
  bar(y);
}

main() {}
