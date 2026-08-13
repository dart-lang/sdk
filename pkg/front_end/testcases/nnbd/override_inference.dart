// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

abstract class A<AT> {
  String method1a(Object x);
  Object method1b(String x);
  void method1c(int x);
  String method1d();
  void method2a(Object? x);
  void method2b(dynamic x);
  void method3a<AT3a>(AT3a x);
  void method3b<AT3b>(AT3b x);
  void method4a<AT4a>(AT4a x, AT y);
  void method4b<AT4b>(AT4b x, AT y);
  void method5a(int x, num y);
  void method5b(int x, num y);
  void method6a({int x, num y});
  void method6b({num y, int x});
  Object? method7a(Object? o, {Object? named}) {}

  Object get getter1a;
  String get getter1b;
  String get getter1c;
  set getter1d(String x);
  int get getter1e;
  set getter1e(int x);

  void set setter1a(Object x);
  void set setter1b(String x);
  void set setter1c(String x);
  String get setter1d;
  int get setter1e;
  set setter1e(int x);

  int? get field1a;
  num? get field1b;
  int? get field1c;

  void set field2a(int? value);
  void set field2b(num? value);
  void set field2c(int? value);

  int? get field3a;
  num? get field3b;
  int? get field3c;

  void set field3a(Object? value);
  void set field3b(Object? value);
  void set field3c(Object? value);

  num? get field4a;
  num? get field4b;
  void set field4b(Object? value);
}

abstract class B<BT> {
  Object method1a(String x);
  String method1b(Object x);
  void method1c(String x);
  int method1d();
  void method2a(dynamic x);
  void method2b(Object? x);
  void method3a<BT3a>(BT3a x);
  void method3b<BT3b>(BT3b x);
  void method4a<BT4a>(BT4a x, BT y);
  void method4b<BT4b>(BT4b x, BT y);
  void method5a(num x, int y);
  void method5b(num x, int y);
  void method6a({Object x, num y});
  void method6b({int x, Object y});
  FutureOr method7a(FutureOr o, {FutureOr named});

  String get getter1a;
  Object get getter1b;
  int get getter1c;
  set getter1d(Object x);
  num get getter1e;
  set getter1e(Object x);

  void set setter1a(String x);
  void set setter1b(Object x);
  void set setter1c(int x);
  Object get setter1d;
  num get setter1e;
  set setter1e(Object x);

  num? get field1a;
  int? get field1b;
  double? get field1c;

  void set field2a(num? value);
  void set field2b(int? value);
  void set field2c(double? value);

  num? get field3a;
  int? get field3b;
  double? get field3c;

  void set field3a(Object? value);
  void set field3b(Object? value);
  void set field3c(Object? value);

  void set field4a(num? value);
  num? get field4b;
  void set field4b(Object? value);
}

abstract class C implements A<int>, B<num> {
  method1a(x);
  method1b(x);
  void method1c(x); // error
  method1d(); // error
  void method2a(x);
  void method2b(x);
  void method3a<CT3a>(x);
  void method3b<CT3b>(x, [y]);
  void method4a<CT4a>(x, y);
  void method4b<CT4b>(x, y, [z]);
  void method5a(x, y); // error
  void method5b(num x, num y, [z]); // error
  void method6a({x, y});
  void method6b({x, y, z});
  method7a(o, {named});

  get getter1a;
  get getter1b;
  get getter1c; // error
  get getter1d;
  get getter1e;

  void set setter1a(x);
  void set setter1b(x);
  void set setter1c(x); // error
  void set setter1d(x);
  void set setter1e(x);

  final field1a = null;
  final field1b = null;
  final field1c = null; // error

  final field2a = null;
  final field2b = null;
  final field2c = null; // error

  final field3a = null;
  final field3b = null;
  final field3c = null; // error

  var field4a = null;
  var field4b = null; // error
}

main() {}
