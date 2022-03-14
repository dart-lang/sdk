// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1 {
  element;
  final int element = 42; // Error.
}

enum E2 {
  element,
  element; // Error.
}

enum E3 {
  element;

  void element() {} // Error.
}

enum E4 {
  element;

  static void element() {} // Error.
}

enum E5 {
  element;

  static int element = 42; // Error.
}

enum E6 {
  element; // Error.

  void set element(E6 value) {}
}

enum E7 {
  element; // Ok.

  static void set element(E7 value) {}
}

class A8 {
  void set element(dynamic value) {}
}

enum E8 with A8 {
  element // Error.
}

class A9 {
  int element = 42;
}

enum E9 with A9 {
  element // Error.
}

class A10 {
  void element() {}
}

enum E10 with A10 {
  element // Error.
}

main() {}
