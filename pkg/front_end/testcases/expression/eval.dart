// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int globalVar = 100;

class MyClass {
  static int staticVar = 1000;

  static void method(int value) {}
}

void testFunction() {
  int i = 0;
  while (true) {
    if (++i % 100000000 == 0) {
      MyClass.method(10000);
    }
  }
}
