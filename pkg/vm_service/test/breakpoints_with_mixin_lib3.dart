// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin class Foo {
  void foo() {
    print('I should be breakable!');
  }
}

class Bar {
  void bar() {
    print('I should be breakable too!');
  }
}
