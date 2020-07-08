// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  String text = "";
}

extension on A? {
  String get text => "Lily was here";
}

void main() {
  A? a = null;
  expect("Lily was here", a.text);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
