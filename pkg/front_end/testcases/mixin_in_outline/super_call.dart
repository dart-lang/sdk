// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'super_call_lib.dart';

abstract class InvalidClass extends Super with Mixin {}

abstract class CompleteSuper extends Super {
  int field = 42;
  void method() {}
  int get getter => 42;
  void set setter(int value) {}
}

class ValidClass extends CompleteSuper with Mixin {}
