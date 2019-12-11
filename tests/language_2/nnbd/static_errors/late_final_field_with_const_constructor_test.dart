// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

// Test that it is not a compile time error for a `final` variable to not have
// an initializer if that variable is declared as `late`.
import 'package:expect/expect.dart';
import 'dart:core';

class C1 {
  static late final a = 0; //# 01: ok
  final a = 0; //# 02: ok
  late final a = 0; //# 03: compile-time error
  const C1();
}

class C2 {
  static late final a = 0; //# 04: ok
  final a = 0; //# 05: ok
  late final a = 0; //# 06: ok
  C2();
}

main() {}
