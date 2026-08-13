// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class NativeBigIntMethods<T> {
  bool get enabled;

  T parse(String string);
  String toStringMethod(T value);

  T fromInt(int i);

  T get one;
  T get eight;

  int bitLength(T value);
  bool isEven(T value);

  T add(T left, T right);
  T shiftLeft(T value, T count);
  T shiftRight(T value, T count);
  T subtract(T left, T right);
}
