// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A reference to a class that is shadowed by a type variable should still work
// in a static context.

class T {
  String toString() => "Class T";
}

class A<T> {
  static method() {
    var foo = new T();
    Expect.equals("Class T", foo.toString());
  }
}

main() {
  A.method();
}
