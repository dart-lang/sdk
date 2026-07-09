// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Base {}

class Foo extends Base {}

class Bar extends Base {}

class Baz extends Base {}

void foo(x) {}

void bar(x) {}

void foo_escaped(x) {}

void bar_escaped(x) {}

void escape(fn) {
  fn(new Baz());
}

main() {
  foo(new Foo());
  bar(new Bar());
  escape(foo_escaped);
  escape(bar_escaped);
}
