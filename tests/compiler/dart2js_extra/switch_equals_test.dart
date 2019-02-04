// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SuperClass {
  const SuperClass();

  bool operator ==(Object other);
}

class Class extends SuperClass {
  const Class();

  bool operator ==(Object other);
}

class SubClass extends Class {
  const SubClass();

  bool operator ==(Object other) => false;
}

main() {
  switch (null) {
    case const SuperClass():
      break;
    default:
  }
  switch (null) {
    case const Class():
      break;
    default:
  }
  switch (null) {
    case const SubClass(): //# 01: compile-time error
      break; //# 01: continued
    default:
  }
}
