// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class NativeBigIntMethods {
  bool get enabled;

  Object parse(String string);
  String toStringMethod(Object value);

  Object fromInt(int i);

  Object get one;
  Object get eight;

  int bitLength(Object value);
  bool isEven(Object value);

  Object add(Object left, Object right);
  Object shiftLeft(Object value, Object count);
  Object shiftRight(Object value, Object count);
  Object subtract(Object left, Object right);
}
