// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

@patch
int get topLevelGetter => 42;

@patch
class Class {
  @patch
  int get instanceGetter => 42;

  @patch
  static int get staticGetter => 42;
}

@patch
extension Extension on int {
  @patch
  int get instanceGetter => 42;

  @patch
  static int get staticGetter => 42;
}

methodInPatch() {
  topLevelGetter;
  Class.staticGetter;
  Extension.staticGetter;
  Class c = new Class();
  c.instanceGetter;
  0.instanceGetter;
}