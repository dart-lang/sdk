// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
  foo<E extends T>(List<E> list) {
    List<E> variable = method(list);
  }

  List<F> method<F extends T>(List<F> list) => list;
}

main() {}
