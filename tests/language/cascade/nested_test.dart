// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Foo {
  int x = 0;
}

class Bar {
  late Foo foo;
  int y = 0;
}

main() {
  var bar = new Bar()
    ..foo = (new Foo()..x = 42)
    ..y = 38;
  Expect.isTrue(bar is Bar);
  Expect.isTrue(bar.foo is Foo);
  Expect.equals(bar.foo.x, 42);
  Expect.equals(bar.y, 38);
}
