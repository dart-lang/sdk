// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  void method() {}
  int property = 42;
}

mixin Mixin on Super {
  void method() {
    super.method();
  }

  int get property {
    return super.property;
  }

  void set property(int value) {
    super.property = value;
  }
}

class Class1 extends Super with Mixin {}

class Class2 with Mixin implements Super {}
