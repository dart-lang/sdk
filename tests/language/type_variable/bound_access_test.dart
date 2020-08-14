// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DynamicClass<T extends dynamic, S extends T> {
  T field1;
  T field2;

  DynamicClass(this.field1, this.field2);

  method() => field1 * field2;
}

class NumClass<T extends num, S extends T> {
  T field1;
  S field2;

  NumClass(this.field1, this.field2);

  num method1() => field1 * field2;

  num method2() => field1 + field2.length;
  //                               ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'length' isn't defined for the class 'num'.
}

main() {
  new DynamicClass<num, int>(0.5, 2).method();
  new NumClass<num, double>(2, 0.5).method1();
  new NumClass<num, double>(2, 0.5).method2();
}
