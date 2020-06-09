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
  // This test verifies that when overriding `==` it is a compile time error to
  // use that class as a key in a switch, but only if the override provides a
  // body. However, with NNBD, all of these switches became compile time errors
  // so now we cast `null` as `dynamic` to get these first two switches past
  // the compiler.
  switch (null as dynamic) {
    case const SuperClass():
      break;
    default:
  }
  switch (null as dynamic) {
    case const Class():
      break;
    default:
  }
  switch (null as dynamic) {
    case const SubClass(): //# 01: compile-time error
      break; //# 01: continued
    default:
  }
  switch (null) {
    case null:
      break;
    default:
  }
}
