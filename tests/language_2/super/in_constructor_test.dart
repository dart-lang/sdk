// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Foo {
  bool myBoolean = false;

  void set foo(bool b) {
    print("Setting foo in Foo");
    myBoolean = b;
  }
}

class Baz extends Foo {
  Baz() {
    super.foo = true;
    Expect.equals(true, super.myBoolean);
  }
}

main() {
  new Baz();
}
