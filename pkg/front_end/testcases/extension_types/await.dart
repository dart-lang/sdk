// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension type V1(Future<int> id) implements Future<int> {}

extension type V2<T extends Future<Object>>(T id) implements Future<Object>{}

main() async {
  V1 v1 = V1(Future<int>.value(42));
  var _v1 = await v1;
  expect(42, _v1);

  V2<Future<String>> v2 = V2(Future<String>.value("42"));
  var _v2 = await v2;
  expect("42", _v2);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}