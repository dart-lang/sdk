// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks for compile-time errors and their absence for some use cases
// of late fields and variables.

class A {
  int a = 42;
  late int b = (this.a * 2) >> 1; // Ok.

  foo(late int x) {}
}

bar(late int x) {}

baz() {
  try {
    throw "baz";
  } on dynamic catch (late e, late t) {}
  for (late int i = 0; i < 10; ++i) {
    print("baz");
  }
  for (late String s in ["baz"]) {
    print(s);
  }
  [for (late int i = 0; i < 10; ++i) i];
}

hest() async {
  await for (late String s in new Stream.fromIterable(["hest"])) {
    print(s);
  }
  return "hest";
}

fisk() async {
  late String s1 = await hest();
  late String s2 = '${fisk}${await hest()}${fisk}';
  late Function f = () async => await hest();
}

class B {
  late final int x = 42;

  const B();
}

class C {
  late final int x;

  initVars() {
    x = 42; // Ok: [x] doesn't have an initializer.
  }
}

main() {}
