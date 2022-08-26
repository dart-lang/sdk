// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {
  T get value => throw '';
  T direct;
  void Function(T) functionArgument;
  T Function() functionReturn;
  T Function(T) functionArgumentReturn;

  Class(this.direct, this.functionArgument, this.functionReturn,
      this.functionArgumentReturn);

  void method(Class<T> other) {
    direct;
    this.direct;
    other.direct;

    functionArgument;
    this.functionArgument;
    other. /*as: void Function(T%)!*/ functionArgument;

    functionArgument(value);
    this.functionArgument(value);
    other. /*as: void Function(T%)!*/ functionArgument(value);

    functionReturn;
    this.functionReturn;
    other.functionReturn;

    functionReturn();
    this.functionReturn();
    other.functionReturn();

    functionArgumentReturn;
    this.functionArgumentReturn;
    other. /*as: T% Function(T%)!*/ functionArgumentReturn;

    functionArgumentReturn(value);
    this.functionArgumentReturn(value);
    other. /*as: T% Function(T%)!*/ functionArgumentReturn(value);
  }
}
