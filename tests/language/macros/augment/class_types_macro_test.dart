// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--enable-experiment=macros

import 'package:expect/expect.dart';

import 'impl/class_types_macro.dart';

@ClassTypesDeclareType(
  name: 'B',
  code: 'class B { `int` get x => 3; }',
)
class A {}

void main() {
  Expect.equals(B().x, 3);
}
