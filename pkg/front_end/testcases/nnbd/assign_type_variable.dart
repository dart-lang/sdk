// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<E> {
  void method(E e) {
    e = id(e);
    e = id<E>(e);
    if (e != null) {
      var e2 = e;
      e2 = id(e);
      e2 = id<E>(e);
      e2 = id(e2);
      e2 = id<E>(e2);
    }
  }
}

T id<T>(T t) => t;

main() {}
