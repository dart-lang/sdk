// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

typedef V F<U, V>(U u);

class Foo<T> {
  Bar<T> get v1 => new Bar();
  Bar<List<T>> get v2 => new Bar();
  Bar<F<T, T>> get v3 => new Bar();
  Bar<F<F<T, T>, T>> get v4 => new Bar();
  List<T> get v5 => [];
  List<F<T, T>> get v6 => [];
  Map<T, T> get v7 => {};
  Map<F<T, T>, T> get v8 => {};
  Map<T, F<T, T>> get v9 => {};
}

class Bar<T> {
  const Bar();
}

main() {}
