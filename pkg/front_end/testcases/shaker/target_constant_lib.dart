// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class A1 {
  static const int staticConstField1 = _A12.staticConstField21;
  static const int staticConstField2 = _A12.staticConstField22;
  static const int staticConstField3 = _A12.staticConstField23;
  static const int staticConstField4 = _A12.staticConstField24;
  static const int staticConstField5 = _A12.staticConstField25;
  static const int staticConstField6 = _A12.staticConstField26;
}

class _A12 {
  static const int staticConstField21 = 42;
  static const int staticConstField22 = 42;
  static const int staticConstField23 = 42;
  static const int staticConstField24 = 42;
  static const int staticConstField25 = 42;
  static const int staticConstField26 = 42;
}

class A2 {
  static final int staticFinalField1 = 42;
  static final int staticFinalField2 = 42;

  static int staticField1 = 42;
  static int staticField2 = 42;
}

class A3 {
  final int instanceFinalField1 = 42;
  final int instanceFinalField2 = 42;

  int instanceField1 = 42;
  int instanceField2 = 42;
}

class B {
  final int instanceFinalField1 = B2.field21;
  final int instanceFinalField2 = B2.field22;

  const B();
}

class B2 {
  static const int field21 = 42;
  static const int field22 = 42;
}
