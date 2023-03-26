// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(https://github.com/dart-lang/sdk/issues/51557): Decide if the mixins
// being applied in this test should be "mixin", "mixin class" or the test
// should be left at 2.19.
// @dart=2.19

import 'package:expect/expect.dart';

// Regression test for http://dartbug.com/51558
//
// Enum classes may have abstract getters in the inheritance chain that, as
// declarations, shadow the `index` of the base class.

abstract class EnumFlag extends Object {
  int get index;

  int get value => 1 << index;
}

enum EnumXY with EnumFlag { x, y }

extension EnumXTExtensions on EnumXY {
  String display() {
    switch (this) {
      case EnumXY.x:
        return 'X';
      case EnumXY.y:
        return 'Y';
    }
  }
}

void main() {
  Expect.equals('X', EnumXY.x.display());

  // This second line is needed so that the abstract getter is resolved.
  Expect.equals(0, EnumXY.x.index);
}
