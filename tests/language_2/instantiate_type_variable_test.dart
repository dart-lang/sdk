// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that you cannot instantiate a type variable.

class Foo<T> {
  Foo() {}
  T make() {
    return new T(); //# 01: runtime error
  }
}

main() {
  new Foo<Object>().make();
}
