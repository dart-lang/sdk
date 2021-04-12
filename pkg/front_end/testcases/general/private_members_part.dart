// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'private_members.dart';

abstract class _AbstractClass {
  abstract int _privateAbstractField;
}

class _Class {
  _Class._privateConstructor();

  factory _Class._privateRedirectingFactory() = _Class._privateConstructor;

  void _privateMethod() {}

  int get _privateGetter => 42;

  void set _privateSetter(int value) {}

  int _privateField = 1;

  int _privateFinalField = 1;
}

extension _Extension on int {
  void _privateMethod() {}

  int get _privateGetter => 42;

  void set _privateSetter(int value) {}

  static int _privateField = 1;

  static int _privateFinalField = 1;
}
