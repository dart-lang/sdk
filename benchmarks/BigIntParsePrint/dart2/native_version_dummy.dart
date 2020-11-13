// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'native_version.dart';

const NativeBigIntMethods nativeBigInt = _DummyMethods();

class _DummyMethods implements NativeBigIntMethods {
  const _DummyMethods();

  @override
  bool get enabled => false;

  static Object bad(String message) => UnimplementedError(message);

  @override
  Object parse(String string) => throw bad('parse');

  @override
  String toStringMethod(Object value) => throw bad('toStringMethod');

  @override
  Object fromInt(int i) => throw bad('fromInt');

  @override
  Object get one => throw bad('one');

  @override
  Object get eight => throw bad('eight');

  @override
  int bitLength(Object value) => throw bad('bitLength');

  @override
  bool isEven(Object value) => throw bad('isEven');

  @override
  Object add(Object left, Object right) => throw bad('add');

  @override
  Object shiftLeft(Object value, Object count) => throw bad('shiftLeft');

  @override
  Object shiftRight(Object value, Object count) => throw bad('shiftRight');

  @override
  Object subtract(Object left, Object right) => throw bad('subtract');
}
