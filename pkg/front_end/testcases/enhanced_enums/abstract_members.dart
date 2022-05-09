// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1 {
  element;

  void foo(); // Error.
}

enum E2 {
  element;

  int get foo; // Error.
}

enum E3 {
  element;

  void set foo(int val); // Error.
}

abstract class InterfaceMethod {
  void foo();
}

enum E4 implements InterfaceMethod { // Error.
  element
}

abstract class InterfaceGetter {
  int get foo;
}

enum E5 implements InterfaceGetter { // Error.
  element
}

abstract class InterfaceSetter {
  void set foo(int val);
}

enum E6 implements InterfaceSetter { // Error.
  element
}

mixin MethodImplementation {
  void foo() {}
}

enum E7 with MethodImplementation {
  element;

  void foo(); // Ok.
}

main() {}
