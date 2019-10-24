// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_version.dart';

const NativeBigIntMethods nativeBigInt = _DummyMethods();

class _DummyMethods implements NativeBigIntMethods {
  const _DummyMethods();

  bool get enabled => false;

  static Object bad(String message) {
    throw UnimplementedError(message);
  }

  Object parse(String string) => bad('parse');
  String toStringMethod(Object value) => bad('toStringMethod');

  Object fromInt(int i) => bad('fromInt');

  Object get one => bad('one');
  Object get eight => bad('eight');

  int bitLength(Object value) => bad('bitLength');
  bool isEven(Object value) => bad('isEven');

  Object add(Object left, Object right) => bad('add');
  Object shiftLeft(Object value, Object count) => bad('shiftLeft');
  Object shiftRight(Object value, Object count) => bad('shiftRight');
  Object subtract(Object left, Object right) => bad('subtract');
}
