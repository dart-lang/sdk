// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

view class Class {
  final int it;

  void instanceMethod() {
    this;
  }
  void instanceMethod2(String s, [int i = 42]) {
    this;
    s;
    i;
  }
  static void staticMethod() {}
}

view class GenericClass<T> {
  final T it;

  void instanceMethod() {
    this;
  }
  void instanceMethod2(String s, {int i = 42}) {
    this;
    s;
    i;
  }
  static void staticMethod() {}
}