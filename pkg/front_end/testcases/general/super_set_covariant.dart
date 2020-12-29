// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SuperClass {
  void set setter(Object o) {}
}

abstract class Class extends SuperClass {
  // TODO(johnniwinther): Should this introduce a concrete forwarding stub, and
  // if so, should the target of the super set below be the forwarding super
  // stub?
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
