// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1([@m int x = m]) {
  static const int m = 42;
}

class C2(int x) { // Error
  static const String int = 'not a type';
}

enum E1([@a int x = m]) {
  a(0);
  static const int m = 42;
}

enum E2(int x) { // Error
  a(0);
  static const String int = 'not a type';
}

extension type ET1([@m int x = m]) {
  static const int m = 42;
}

extension type ET2(int x) { // Error
  static const String int = 'not a type';
}
