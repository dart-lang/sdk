// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Tests the type checking when passing code into closure from inside a factory method

import "package:expect/expect.dart";

abstract class Foo<T> {
  factory Foo.from() = Bar<T>.from;
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
  Expect.equals(false, gotError);
}
