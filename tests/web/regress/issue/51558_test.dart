// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Regression test for http://dartbug.com/51558
//
// Enum classes may have abstract getters in the inheritance chain that, as
// declarations, shadow the `index` of the base class.

mixin EnumFlag {
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
