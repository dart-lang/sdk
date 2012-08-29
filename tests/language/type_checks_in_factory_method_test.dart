// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks --enable_asserts
// Tests the type checking when passing code into closure from inside a factory method

interface Foo<T> default Bar<T> {
  Foo.from();
}

class Bar<T> implements Foo<T> {
  Bar() {}

  factory Bar.from() {
    var func = (T arg) {
      T foo = arg;
      bool isString = foo is String;
      print(arg);
      print(" String=$isString");
    };

    func("Hello World!"); // If T is not String, dynamic type checks should fail
    return new Bar<T>();
  }
}

main() {
  Foo<String> value1;
  value1 = new Foo<String>.from();

  bool gotError = false;

  try {
    Foo<int> value2 = new Foo<int>.from();
  } on TypeError catch (e) {
    gotError = true;
  }
  Expect.equals(true, gotError);
}
