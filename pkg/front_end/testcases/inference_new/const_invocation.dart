// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

typedef V F<U, V>(U u);

class Foo<T> {
  Bar<T> get v1 => const Bar();
  Bar<List<T>> get v2 => const Bar();
  Bar<F<T, T>> get v3 => const Bar();
  Bar<F<F<T, T>, T>> get v4 => const Bar();
  List<T> get v5 => const [];
  List<F<T, T>> get v6 => const [];
  Map<T, T> get v7 => const {};
  Map<F<T, T>, T> get v8 => const {};
  Map<T, F<T, T>> get v9 => const {};
}

class Bar<T> {
  const Bar();
}

main() {}
