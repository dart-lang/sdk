// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See reatiningPath.txt for expected behavior.

class Foo {
  var a;
  var b;
  Foo(this.a, this.b);
}

main() {
  var list = new List<Foo>(10);
  list[5] = new Foo(42.toString(), new Foo(87.toString(), 17.toString()));
  while (true) {}
}
