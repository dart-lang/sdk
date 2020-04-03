// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1<T> {}

extension A2<T> on A1<T> {
  A1<T> method1<S extends T>() {
    return this;
  }

  A1<T> method2<S extends A1<T>>(S o) {
    print(o);
    print(T);
    print(S);
    return this;
  }
}

extension A3<T extends A1<T>> on A1<T> {
}

extension A4<T> on A1<T> {
  method<T>() {}
}

main() {}