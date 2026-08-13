// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<U> {
  A();

  factory A.foo(U j) {
    void func<T>(T i, U j) {
      print(i);
      print(j);
    }

    func(3, j);

    return A();
  }
}

void main() {
  A.foo('hi');
}
