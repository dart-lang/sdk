// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F = void Function();

void foo() {}
F bar() => foo;
F? baz() => foo;
void Function() hest() => foo;
void Function()? fisk() => foo;

Function()? foobar(Function()? x) => null;

class A<T> {}
class B extends A<Function()?> {
  Function()? method(Function()? x) => null;
}

main() {
  void Function() g = () {};
  void Function()? f = g;

  var fBar = bar();
  var fBaz = baz();
  var fHest = hest();
  var fFisk = fisk();
}
