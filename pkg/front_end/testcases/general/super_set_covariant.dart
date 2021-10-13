// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

class SuperClass {
  void set setter(Object o) {}
}

abstract class Class extends SuperClass {
  // This introduces a forwarding semi stub with the parameter type of
  // the `SuperClass.setter` but with a signature type of `void Function(int)`.
  void set setter(covariant int o);
}

class SubClass extends Class {
  void set setter(covariant int o) {
    super.setter = '$o';
  }
}

test() {
  new SubClass().setter = 0;
}

main() {}
