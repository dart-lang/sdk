// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Base {
  int method1(int i) => i;

  int method2(int i, {int? j}) => i;

  int method3<T>(int i, {int? j}) => i;

  int method4<T>(int i, {int? j}) => i;
}
