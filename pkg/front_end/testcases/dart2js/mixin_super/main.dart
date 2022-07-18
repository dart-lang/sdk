// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

mixin Mixin1 on Super1, Super2 {
  late int field1 = () {
    return super.field1 = super.field1 + 1;
  }();

  late int field2 = () {
    return 88;
  }();

  void method1() {
    super.method1();
  }

  void method2() {}

  int get property1 {
    return super.property1;
  }

  void set property1(int value) {
    super.property1 = value;
  }

  int get property2 {
    return 42;
  }

  void set property2(int value) {}
}

abstract class Class1a extends Super1 implements Super2 {}

class Class1b extends Class1a with Mixin1 /* Ok */ {}

abstract class Class2a extends Super2 implements Super1 {}

class Class2b extends Class2a with Mixin1 /* Error */ {}

abstract class Class3a implements Super1, Super2 {}

class Class3b extends Class3a with Mixin1 /* Error */ {}

abstract class Class4a extends Super1 implements Super2 {}

class Class4b extends Class4a with Mixin2 /* Ok */ {}

abstract class Class5a extends Super2 implements Super1 {}

class Class5b extends Class5a with Mixin2 /* Error */ {}

abstract class Class6a implements Super1, Super2 {}

class Class6b extends Class6a with Mixin2 /* Error */ {}
