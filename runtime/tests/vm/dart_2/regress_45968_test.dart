// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Regression test for https://github.com/dart-lang/sdk/issues/45968.
// Verifies that compiler doesn't crash if annotation references field
// which is replaced with a getter.

class Qualifier {
  final String name;
  const Qualifier(this.name);
}

class Foo implements Qualifier {
  String get name => 'a';
}

class Bar {
  @Qualifier('b')
  void bar() {}
}

Qualifier x = Foo();

main() {
  print(x.name);
  Bar().bar();
}
