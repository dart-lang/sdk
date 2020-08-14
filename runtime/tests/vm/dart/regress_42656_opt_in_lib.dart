// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opted-in library for regress_42656_test.dart.

import 'regress_42656_opt_out_lib.dart' show MixinB;

mixin MixinA {
  int x = 42;

  @override
  String toString() => 'MixinA';
}

abstract class C1 with MixinA {}

class C2 extends C1 {}

abstract class D1 with MixinB {}

class D2 extends D1 {}
