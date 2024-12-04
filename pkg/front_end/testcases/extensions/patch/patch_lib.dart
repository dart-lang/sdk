// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

@patch
extension IntExtension on int {
  @patch
  int method1() => 42;

  int method2() => 43;
}

_method2() {
  0.method1();
  0.method2();
}
