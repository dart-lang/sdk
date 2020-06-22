// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class WrapT<T> {
  Type get type => T;
}

printAndCheck(t) {
  print(t);
  Expect.equals(String, t);
}

class MyClass<T> {
  factory MyClass.works() {
    Type t = new WrapT<T>().type;
    printAndCheck(t);
    return MyClass._();
  }

  factory MyClass.works2() {
    printAndCheck(T);
    return MyClass._();
  }

  MyClass._();
}

main() {
  new MyClass<String>.works();
  new MyClass<String>.works2();
}
