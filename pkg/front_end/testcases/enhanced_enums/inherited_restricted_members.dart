// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {
  int get hashCode => 42;
}

enum E1 with A1 { // Error.
  element
}

class A2 {
  int get values => 42;
}

enum E2 with A2 { // Error.
  element
}

class A3 {
  int get index => 42;
}

enum E3 with A3 { // Error.
  element
}

class A4 {
  bool operator==(Object other) => true;
}

enum E4 with A4 { // Error.
  element
}

mixin M5 {
  int get hashCode => 42;
}

enum E5 with M5 { // Error.
  element
}

mixin M6 {
  int get values => 42;
}

enum E6 with M6 { // Error.
  element
}

mixin M7 {
  int get index => 42;
}

enum E7 with M7 { // Error.
  element
}

mixin M8 {
  bool operator==(Object other) => true;
}

enum E8 with M8 { // Error.
  element
}

abstract class A9 {
  int get index;
  int get hashCode;
  bool operator==(Object other);
}

enum E9 with A9 { // Ok.
  element
}

mixin M10 {
  int get index;
  int get hashCode;
  bool operator==(Object other);
}

enum E10 with M10 { // Ok.
  element
}

main() {}
