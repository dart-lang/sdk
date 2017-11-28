// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart2js regression test: Test that the type mask for non-null exact Mixin is
// created for Mixin.getter.

import 'package:expect/expect.dart';

class Mixin {
  @NoInline()
  get getter => 42;
}

class Superclass {}

class Subclass extends Superclass with Mixin {
  method() => super.getter;
}

void main() {
  Expect.equals(42, new Subclass().method());
}
