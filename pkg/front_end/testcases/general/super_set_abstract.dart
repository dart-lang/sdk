// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SuperClass {
  void set setter(int o) {}
}

abstract class Class extends SuperClass {
  void set setter(Object o);
}

class SubClass extends Class {
  void set setter(Object o) {
    super.setter = '$o';
  }
}

test() {
  new SubClass().setter = '0';
}

main() {}
