// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A1 implements Enum {
  int get index => 0; // Error.
  bool operator==(Object other) => true; // Error.
  int get hashCode => 1; // Error.
}

mixin M1 implements Enum {
  int get index => 0; // Error.
  bool operator==(Object other) => true; // Error.
  int get hashCode => 1; // Error.
}

abstract class A2 implements Enum {
  void set index(String value) {} // Error.
  void set hashCode(double value) {} // Error.
}

mixin M2 implements Enum {
  void set index(String value) {} // Error.
  void set hashCode(double value) {} // Error.
}

abstract class A3 implements Enum {
  int get index; // Ok.
  bool operator==(Object other); // Ok.
  int get HashCode; // Ok.
}

mixin M3 implements Enum {
  int get index; // Ok.
  bool operator==(Object other); // Ok.
  int get HashCode; // Ok.
}

abstract class A4 implements Enum {
  int index = 0; // Error.
  int hashCode = 1; // Error.
}

mixin M4 implements Enum {
  int index = 0; // Error.
  int hashCode = 1; // Error.
}

abstract class A5 implements Enum {
  int foo = 0, bar = 1, // Ok.
    index = 2, // Error.
    hashCode = 3; // Error.
}

mixin M5 implements Enum {
  int foo = 0, bar = 1, // Ok.
    index = 2, // Error.
    hashCode = 3; // Error.
}

main() {}
