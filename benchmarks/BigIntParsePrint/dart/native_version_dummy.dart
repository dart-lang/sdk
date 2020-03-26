// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'native_version.dart';

const NativeBigIntMethods nativeBigInt = _DummyMethods();

class _DummyMethods implements NativeBigIntMethods {
  const _DummyMethods();

  bool get enabled => false;

  static Object bad(String message) => UnimplementedError(message);

  Object parse(String string) => throw bad('parse');
  String toStringMethod(Object value) => throw bad('toStringMethod');

  Object fromInt(int i) => throw bad('fromInt');

  Object get one => throw bad('one');
  Object get eight => throw bad('eight');

  int bitLength(Object value) => throw bad('bitLength');
  bool isEven(Object value) => throw bad('isEven');

  Object add(Object left, Object right) => throw bad('add');
  Object shiftLeft(Object value, Object count) => throw bad('shiftLeft');
  Object shiftRight(Object value, Object count) => throw bad('shiftRight');
  Object subtract(Object left, Object right) => throw bad('subtract');
}
