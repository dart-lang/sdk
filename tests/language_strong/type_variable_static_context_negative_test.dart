// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A type variable can't be referenced in a static class

class A<T> {
  static int method() {
    var foo =
        new T(); // error, can't reference a type variable in a static context
  }
}

main() {
  A.method();
}
