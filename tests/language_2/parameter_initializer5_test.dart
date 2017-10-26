// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Use the this.x parameter in an initializer expression.

class Foo {
  var x, y;
  Foo(this.x) : y = x {}
}

main() {
  new Foo(12);
}
