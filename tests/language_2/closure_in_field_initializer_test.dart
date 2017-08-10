// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Foo {
  var closures = {'a': (int x, int y) => x + y};
}

main() {
  var closures = new Foo().closures;
  Expect.equals(6, closures['a'](4, 2));
}
