// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=extension-methods

class A1 {}

extension A2 on A1 {
  A1 method1() {
    return this;
  }

  A1 method2<T>(T o) {
    print(o);
    return this;
  }
}

class B1<T> {}

extension B2<T> on B1<T> {
  B1<T> method1() {
    return this;
  }

  B1<T> method2<S>(S o) {
    print(o);
    return this;
  }
}

main() {}