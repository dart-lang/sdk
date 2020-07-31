// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library main;

import 'member_inheritance_from_opt_out_lib.dart';

abstract class Interface {
  int method1();

  int? method2();

  int method3a(int a, int b);

  int method3b(int a, [int b]);

  int method3c([int a, int b]);

  int? method4a(int? a, int? b);

  int? method4b(int? a, [int? b]);

  int? method4c([int? a, int? b]);

  int method5a(int a, {int b: 0});

  int method5b({int a: 0, int b: 0});

  int method5c({required int a, required int b});

  int? method6a(int? a, {int? b});

  int? method6b({int? a, int? b});

  int? method6c({required int? a, required int? b});

  int get getter1;

  int? get getter2;

  void set setter1(int value);

  void set setter2(int? value);

  int field1 = 0;

  int? field2;

  int get field3;

  void set field3(int value);

  int? get field4;

  void set field4(int? value);

  int get property1;

  void set property1(int value);

  int? get property2;

  void set property2(int? value);

  int property3 = 0;

  int? property4;
}

class Class1 extends LegacyClass {}

class Class2a extends LegacyClass implements Interface {}

class Class2b extends LegacyClass implements Interface {
  int method1() => 0;

  int? method2() => 0;

  int method3a(int a, int b) => 0;

  int method3b(int a, [int b = 42]) => 0;

  int method3c([int a = 42, int b = 42]) => 0;

  int? method4a(int? a, int? b) => 0;

  int? method4b(int? a, [int? b]) => 0;

  int? method4c([int? a, int? b]) => 0;

  int method5a(int a, {int b: 0}) => 0;

  int method5b({int a: 0, int b: 0}) => 0;

  int method5c({required int a, required int b}) => 0;

  int? method6a(int? a, {int? b}) => 0;

  int? method6b({int? a, int? b}) => 0;

  int? method6c({required int? a, required int? b}) => 0;

  int get getter1 => 0;

  int? get getter2 => 0;

  void set setter1(int value) {}

  void set setter2(int? value) {}

  int field1 = 0;

  int? field2;

  int get field3 => 0;

  void set field3(int value) {}

  int? get field4 => 0;

  void set field4(int? value) {}

  int get property1 => 0;

  void set property1(int value) {}

  int? get property2 => 0;

  void set property2(int? value) {}

  int property3 = 0;

  int? property4;
}

class Class3a extends GenericLegacyClass<int> {}

class Class3b extends GenericLegacyClass<int?> {}

class Class3c<S> extends GenericLegacyClass<S> {}

main() {}
