// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type Foo(dynamic d) {
  // Bad
  var foo = this();

  bar() {
    // OK
    return this;
  }
}

class FooClass {
  // Bad
  var foo = this();

  bar() {
    // OK
    return this;
  }
}
