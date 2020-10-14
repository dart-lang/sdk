// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  final int x;
  const Foo(this.x)
      : assert(x > 0, "x is not positive"),
        assert(x > 0),
        assert(const bool.fromEnvironment("foo") == false,
            "foo was ${const bool.fromEnvironment("foo")}"),
        assert(const bool.fromEnvironment("foo") == false);
  const Foo.withMessage(this.x)
      : assert(x < 0, "btw foo was ${const bool.fromEnvironment("foo")}");
  const Foo.withInvalidMessage(this.x) : assert(x < 0, x);
  const Foo.withInvalidCondition(this.x) : assert(x);
}

class Bar {
  final int x;
  const Bar.withMessage(this.x) : assert(x < 0, "x is not negative");
  const Bar.withoutMessage(this.x) : assert(x < 0);
}

const Foo foo1 = const Foo(1);
const Foo foo2 = const Foo(0);
const Foo foo3 = const Foo.withMessage(42);
const Foo foo4 = const Foo.withInvalidMessage(42);
const Foo foo5 = const Foo.withInvalidCondition(42);
const Bar bar1 = const Bar.withMessage(1);
const Bar bar2 = const Bar.withMessage(0);
const Bar bar3 = const Bar.withoutMessage(1);
const Bar bar4 = const Bar.withoutMessage(0);

main() {
  print(foo1);
}
