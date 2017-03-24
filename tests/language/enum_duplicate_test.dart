// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for duplicate enums.

library enum_duplicate_test;

import 'package:expect/expect.dart';

import 'enum_duplicate_lib.dart' as lib; //# 01: ok
import 'enum_duplicate_lib.dart' as lib; //# 02: ok

enum Enum1 {
  A,
  B,
}

enum Enum2 {
  A,
  B,
}

main() {
  Expect.equals('Enum1.A,Enum1.B', Enum1.values.join(','));
  Expect.equals('Enum1.A,Enum1.B', lib.Enum1.values.join(',')); //# 01: continued
  Expect.equals('Enum2.A,Enum2.B', Enum2.values.join(','));
  Expect.equals('Enum2.A,Enum2.B', lib.Enum2.values.join(',')); //# 02: continued
}
