// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

class Class<T> {
  T direct() => null;
  void Function(T) functionArgument() => null;
  T Function() functionReturn() => null;
  T Function(T) functionArgumentReturn() => null;

  void method(Class<T> other) {
    direct;
    this.direct;
    other.direct;

    direct();
    this.direct();
    other.direct();

    functionArgument;
    this.functionArgument;
    other. /*as: void Function(T) Function()*/ functionArgument;

    functionArgument();
    this.functionArgument();
    other. /*as: void Function(T)*/ functionArgument();

    functionArgument()(null);
    this.functionArgument()(null);
    other. /*as: void Function(T)*/ functionArgument()(null);

    functionReturn;
    this.functionReturn;
    other.functionReturn;

    functionReturn();
    this.functionReturn();
    other.functionReturn();

    functionReturn()();
    this.functionReturn()();
    other.functionReturn()();

    functionArgumentReturn;
    this.functionArgumentReturn;
    other. /*as: T Function(T) Function()*/ functionArgumentReturn;

    functionArgumentReturn();
    this.functionArgumentReturn();
    other. /*as: T Function(T)*/ functionArgumentReturn();

    functionArgumentReturn()(null);
    this.functionArgumentReturn()(null);
    other. /*as: T Function(T)*/ functionArgumentReturn()(null);
  }
}
