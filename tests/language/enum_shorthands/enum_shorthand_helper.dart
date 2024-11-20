// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Common classes and enums for testing enum shorthands.

// SharedOptions=--enable-experiment=enum-shorthands

enum Color { blue, red, green }

class Integer {
  static Integer get one => Integer(1);
  static const Integer constOne = const Integer._(1);
  static const Integer constTwo = const Integer._(2);
  final int integer;
  Integer(this.integer);
  const Integer._(this.integer);
}

extension type IntegerExt(int integer) {
  static IntegerExt get one => IntegerExt(1);
  static const IntegerExt constOne = const IntegerExt._(1);
  static const IntegerExt constTwo = const IntegerExt._(2);
  const IntegerExt._(this.integer);
}
