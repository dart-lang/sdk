// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import 'generic_override.dart';

abstract class LegacyClass1 {
  void method1a<T>();
  void method1b<T>();
  void method1c<T>();
  void method2a<T extends Object>();
  void method2b<T extends Object>();
  void method2c<T extends Object>();
  void method3a<T extends dynamic>();
  void method3b<T extends dynamic>();
  void method3c<T extends dynamic>();

  void method4a<T extends Object>();
  void method4b<T extends Object>();
  void method4c<T extends Object>();

  void method5a<T extends Class1>();
  void method5b<T extends Class1>();
  void method5c<T extends Class1>();
}

abstract class LegacyClass2 extends Class1 {
  void method1a<T>();
  void method1b<T extends Object>();
  void method1c<T extends dynamic>();
  void method2a<T>();
  void method2b<T extends Object>();
  void method2c<T extends dynamic>();
  void method3a<T>();
  void method3b<T extends Object>();
  void method3c<T extends dynamic>();

  void method4a<T extends Object>();
  void method4b<T extends Object>();
  void method4c<T extends Object>();

  void method5a<T extends Class1>();
  void method5b<T extends Class1>();
  void method5c<T extends Class1>();
}

abstract class LegacyClass3 extends Class1 {}

main() {}
