// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super1 {
  void method1() {}
  int field1 = 42;
  int property1 = 42;
}

class Super2 {
  void method2() {}
  int field2 = 87;
  int property2 = 87;
}

mixin Mixin2 on Super1, Super2 {
  late int field1 = () {
    return super.field1 = super.field1 + 1;
  }();

  late int field2 = () {
    return 88;
  }();

  void method1() {
    super.method1();
  }

  void method2() {}

  int get property1 {
    return super.property1;
  }

  void set property1(int value) {
    super.property1 = value;
  }

  int get property2 {
    return 42;
  }

  void set property2(int value) {}
}
