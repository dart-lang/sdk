// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class Foo {
  const Foo(int i) : assert(i > 0);
}

foo() {
  new Foo(0);
}
