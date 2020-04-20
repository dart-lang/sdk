// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {}

extension Extension on Class {
  T id<T>(T t) => t;

  T Function<T>(T) get getter => id;

  method() {
    String Function(String) stringId = id;
  }

  errors() {
    int Function(int) intId = getter;
  }
}


main() {
  Class c = new Class();
  int Function(int) intId = c.id;
  double Function(double) doubleId = Extension(c).id;
}

errors() {
  Class c = new Class();
  num Function(num) numId = c.getter;
  bool Function(bool) boolId = Extension(c).getter;
}

