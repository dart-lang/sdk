// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opted-out library for regress_42656_test.dart.
// @dart = 2.8

import 'regress_42656_opt_in_lib.dart' show MixinA;

class MixinB {
  int y = 3;

  @override
  String toString() => 'MixinB';
}

abstract class E1 with MixinA {}

class E2 extends E1 {}

abstract class F1 with MixinB {}

class F2 extends F1 {}
