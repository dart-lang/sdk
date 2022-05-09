// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1 {
  element;

  int get index => 42; // Error.
}

enum E2 {
  element;

  String get index => "foo"; // Error.
}

enum E3 {
  element;

  final int index = 42; // Error.
}

enum E4 {
  element;

  List<String> index() => []; // Error.
}

enum E5 {
  element;

  Never get index => throw 42; // Error.
}

enum E6 {
  element;

  final int foo = 0, index = 1, bar = 2; // Error.
}

enum E7 {
  element;

  void set index(int value) {} // Ok.

  int get index; // Ok.
}

enum E8 {
  element;

  void set index(String value) {} // Error.
}

enum E9 {
  element;

  double get index; // Error.
}

enum E10 {
  element;

  static int get index => 42; // Error.
}

enum E11 {
  element;

  static void set index(int value) {} // Error.
}

enum E12 {
  index // Error.
}

abstract class I13 {
  int get index;
}

enum E13 implements I13 { element } // Ok.

abstract class I14 {
  Never get index;
}

enum E14 implements I14 { element } // Error.

main() {}
