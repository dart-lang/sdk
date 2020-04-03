// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface {
  int? method1();

  int method2();

  int method3();

  int? method4();

  int method5a(int a, int? b);

  int method5b(int a, [int? b]);

  int method5c([int a = 0, int? b]);

  int? method6a(int? a, int b);

  int? method6b(int? a, [int b = 0]);

  int? method6c([int? a, int b = 0]);

  int method7a(int a, {int? b});

  int method7b({int a: 0, int? b});

  int? method8a(int? a, {int b: 0});

  int? method8b({int? a, int b: 0});

  int method9a(int a, {required int? b});

  int method9b({required int a, required int? b});

  int? method10a(int? a, {required int b});

  int? method10b({required int? a, required int b});

  int? get getter1;

  int get getter2;

  int get getter3;

  int? get getter4;

  void set setter1(int? value);

  void set setter2(int value);

  void set setter3(int value);

  void set setter4(int? value);

  int? field1;

  int field2 = 0;

  int field3 = 0;

  int? field4;

  int? get property1;

  void set property1(int? value);

  int get property2;

  void set property2(int value);

  int get property3;

  void set property3(int value);

  int? get property4;

  void set property4(int? value);

  int? get property5;

  void set property5(int? value);

  int get property6;

  void set property6(int value);

  int get property7;

  void set property7(int value);

  int? get property8;

  void set property8(int? value);
}

class Class {
  int method1() => 0;

  int? method2() => 0;

  int method5a(int a, int? b) => 0;

  int method5b(int a, [int? b]) => 0;

  int method5c([int a = 0, int? b]) => 0;

  int method7a(int a, {int? b}) => 0;

  int method7b({int a = 0, int? b}) => 0;

  int method9a(int a, {required int? b}) => 0;

  int method9b({required int a, required int? b}) => 0;

  int get getter1 => 0;

  int? get getter2 => 0;

  void set setter1(int value) {}

  void set setter2(int? value) {}

  int field1 = 0;

  int? field2;

  int get property1 => 0;

  void set property1(int value) {}

  int? get property2 => 0;

  void set property2(int? value) {}

  int property5 = 0;

  int? property6;
}
