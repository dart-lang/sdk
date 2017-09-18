// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'private_nodes_lib.dart';

class _PrivateClass1 {
  A1 publicField1;
}

class _PrivateClass2 {
  A2 publicField2;
  A3 _privateField2;

  _PrivateClass2();
  _PrivateClass2._privateConstructor();

  void publicMethod2() {}
  void _privateMethod2() {}
}

class _PrivateClass21 extends _PrivateClass2 {
  A4 publicField21;
  A5 _privateField21;

  _PrivateClass21();
  _PrivateClass21.publicConstructor();
  _PrivateClass21._privateConstructor();

  void publicMethod21() {
    _privateMethod2();
    _privateMethod21();
  }

  void _privateMethod21() {}
}

class _PrivateClass22 extends _PrivateClass2 {}

class PublicClass extends _PrivateClass21 {
  A6 publicField;
  A7 _privateField;

  PublicClass() : super.publicConstructor();
  PublicClass._privateConstructor() : super._privateConstructor();

  void publicMethod() {}
  void _privateMethod() {}
}

A8 publicField;

A9 _privateField;

A10 publicFunction() => null;

A11 _privateFunction() => null;
