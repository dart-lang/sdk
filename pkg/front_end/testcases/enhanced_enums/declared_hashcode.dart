// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1 {
  element;

  int get hashCode => 42; // Error.
}

enum E2 {
  element;

  String get hashCode => "foo"; // Error.
}

enum E3 {
  element;

  final int hashCode = 42; // Error.
}

enum E4 {
  element;

  List<String> hashCode() => []; // Error.
}

enum E5 {
  element;

  Never get hashCode => throw 42; // Error.
}

enum E6 {
  element;

  final int foo = 0, hashCode = 1, bar = 2; // Error.
}

enum E7 {
  element;

  void set hashCode(int value) {} // Ok.

  int get hashCode; // Ok.
}

enum E8 {
  element;

  void set hashCode(String value) {} // Error.
}

enum E9 {
  element;

  double get hashCode; // Error.
}

enum E10 {
  element;

  static int get hashCode => 42; // Error.
}

enum E11 {
  element;

  static void set hashCode(int value) {} // Error.
}

enum E12 {
  hashCode // Error.
}

abstract class I13 {
  int get hashCode;
}

enum E13 implements I13 { element } // Ok.

abstract class I14 {
  Never get hashCode;
}

enum E14 implements I14 { element } // Error.

main() {}
