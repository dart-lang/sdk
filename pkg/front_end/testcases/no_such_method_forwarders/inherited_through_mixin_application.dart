// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String console = "";

class A {
  String? get g => "g";
}

class C implements A {
  noSuchMethod(Invocation i) {
    console = "C";
  }
}

mixin M on A {
  test() {
    super.g;
  }

  noSuchMethod(Invocation i) {
    console = "M";
  }
}

class MA extends C with M {}

main() {
  new MA().g;
  expect("M", console);
  new MA().test();
  expect("M", console);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
