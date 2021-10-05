// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type A<T> on Class<T> {}

class Class<T> {
  static A<T>? method1(A<T> arg) {
    A<T>? local;
  }
  static A<A<T>>? method2(A<A<T>> arg) {
    A<A<T>>? local;
  }
}

main() {}