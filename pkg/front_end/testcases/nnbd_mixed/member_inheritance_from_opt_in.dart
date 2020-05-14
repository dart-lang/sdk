// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.5

/*cfe.library: nnbd=false*/

import 'member_inheritance_from_opt_in_lib.dart';

class LegacyClass extends Class implements Interface {
  int method3() => 0;

  int method4() => 0;

  int method6a(int a, int b) => 0;

  int method6b(int a, [int b]) => 0;

  int method6c([int a, int b]) => 0;

  int method8a(int a, {int b: 0}) => 0;

  int method8b({int a, int b: 0}) => 0;

  int method10a(int a, {int b}) => 0;

  int method10b({int a, int b}) => 0;

  int get getter3 => 0;

  int get getter4 => 0;

  void set setter3(int value) {}

  void set setter4(int value) {}

  int field3;

  int field4;

  int get property3 => 0;

  void set property3(int value) {}

  int get property4 => 0;

  void set property4(int value) {}

  int property7;

  int property8;
}

main() {}
