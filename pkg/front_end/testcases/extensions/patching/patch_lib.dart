// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

@patch
extension Extension on String {
  @patch
  int instanceMethod() => 42;

  @patch
  T genericInstanceMethod<T>(T t) => t;

  @patch
  static int staticMethod() => 87;

  @patch
  static T genericStaticMethod<T>(T t) => t;

  @patch
  int get instanceProperty => 123;

  @patch
  void set instanceProperty(int value) {}

  @patch
  static int get staticProperty => 237;

  @patch
  static void set staticProperty(int value) {}
}

@patch
extension GenericExtension<T> on T {
  @patch
  int instanceMethod() => 42;

  @patch
  T genericInstanceMethod<T>(T t) => t;

  @patch
  static int staticMethod() => 87;

  @patch
  static T genericStaticMethod<T>(T t) => t;

  @patch
  int get instanceProperty => 123;

  @patch
  void set instanceProperty(int value) {}

  @patch
  static int get staticProperty => 237;

  @patch
  static void set staticProperty(int value) {}
}
