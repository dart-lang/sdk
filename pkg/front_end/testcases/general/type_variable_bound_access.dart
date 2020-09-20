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
}

class Class<X5 extends X4, X4 extends X3, X3 extends X2, X2 extends X1,
    X1 extends X0, X0 extends int> {
  X0 field0;
  X1 field1;
  X2 field2;
  X3 field3;
  X4 field4;
  X5 field5;

  method() {
    field0.isEven;
    field1.isEven;
    field2.isEven;
    field3.isEven;
    field4.isEven;
    field5.isEven;
  }
}

main() {
  new DynamicClass<num, int>(0.5, 2).method();
  new NumClass<num, double>(2, 0.5).method1();
}
