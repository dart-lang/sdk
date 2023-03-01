// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

// Dart test for testing access to private fields on mixins.

library private_mixin2_other;

class C1 {
  int _field = 42;
}

class C2 extends Object with C1 {
  int get field => _field;
}
