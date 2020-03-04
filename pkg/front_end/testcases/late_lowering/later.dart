// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9999

// This test checks for compile-time errors and their absence for some use cases
// of late fields and variables.

class A {
  int a = 42;
  late int b = (this.a * 2) >> 1; // Not an error.

  foo(late int x) {} // Error.
}

bar(late int x) {} // Error.

baz() {
  try {
    throw "baz";
  } on dynamic catch (late e, late t) {} // Error.
  for (late int i = 0; i < 10; ++i) { // Error.
    print("baz");
  }
  for (late String s in ["baz"]) { // Error.
    print(s);
  }
  [for (late int i = 0; i < 10; ++i) i]; // Error.
}

hest() async {
  await for (late String s in new Stream.fromIterable(["hest"])) { // Error.
    print(s);
  }
  return "hest";
}

fisk() async {
  late String s1 = await hest(); // Error.
  late String s2 = '${fisk}${await hest()}${fisk}'; // Error.
  late Function f = () async => await hest(); // Not an error.
}

class B {
  late final int x = 42;

  const B(); // Error: B has late final fields.
}

class C {
  late final int x;

  initVars() {
    x = 42; // Ok: [x] doesn't have an initializer.
  }
}

main() {}
