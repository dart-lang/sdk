// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class Mixin {
  var field;
  foo() => 87;
}

class Foo extends Object with Mixin {
  foo() => super.foo();
  bar() => super.field;
}

main() {
  var f = new Foo();
  f.field = 42;
  print(f.bar());
}
