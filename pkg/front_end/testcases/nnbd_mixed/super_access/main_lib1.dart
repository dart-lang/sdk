// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'main_lib2.dart';

abstract class Mixin1<T> implements Interface<Value, Object> {}

abstract class Mixin2<T> implements Interface<Value, Object> {
  Typedef field;
  Typedef method1() => null;
  void method2(Typedef t) {}
}
