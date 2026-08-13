// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  int get value;
  factory A({int value}) = _AImpl;
}

class _AImpl implements A {
  final int value;
  _AImpl({this.value = 0});
}

const _new = A.new;
const _newImpl = _AImpl.new;

void main(List<String> args) {
  expect(0, A().value);
  expect(0, A.new().value);
  expect(0, _new().value);
  expect(0, (A.new)().value);
  expect(0, _AImpl().value);
  expect(0, _AImpl.new().value);
  expect(0, _newImpl().value);
  expect(0, (_AImpl.new)().value);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
