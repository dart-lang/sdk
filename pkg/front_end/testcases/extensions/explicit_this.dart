// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {
  Object field;
  void method1() {}
}

extension A2 on A1 {
  void method2() => this.method1();

  Object method3() => this.field;

  void method4(Object o) {
    this.field = o;
  }
}

main() {
}