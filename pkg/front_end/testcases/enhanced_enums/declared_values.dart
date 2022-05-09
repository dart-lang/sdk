// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1 {
  element;

  static const List<E1> values = [E1.element]; // Error in E1.
}

enum E2 {
  element;

  int values = 42; // Error in E2.
}

enum E3 {
  element;

  static const List<E3> values = [E3.element]; // Error in E3.
  int values = 42; // Duplicate.
}

enum E4 {
  element;

  static void set values(List<E4> x) {} // Ok.
}

enum E5 {
  element;

  static void set values(dynamic x) {} // Ok.
}

enum E6 {
  element;

  static void set values(Never x) {} // Error in E6.
}

enum E7 {
  element;

  void values() {} // Error in E7.
}

main() {}
