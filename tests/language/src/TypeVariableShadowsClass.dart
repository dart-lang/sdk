// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A reference to a class that is shadowed by a type variable should still work
// in a static context.

class T {
  String toString() => "Class T";
  static String staticToString() => "Class T (static)";
}

class A<T> {
  static method() {
    var foo = new T();
    Expect.equals("Class T", foo.toString());
  }
  instMethod() {
    var foo = T.staticToString();
    Expect.equals("Class T (static)", foo);
  }
}

main() {
  A.method();
  new A<String>().instMethod();
}
