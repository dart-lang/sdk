// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  // ignore: unused_local_variable
  Foo foo = new Foo.named();
}

class Foo {
  /*nm*/ Foo.named() {
    print("foo");
  }
}
