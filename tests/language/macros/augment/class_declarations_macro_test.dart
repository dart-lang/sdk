// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--enable-experiment=macros

import 'package:expect/expect.dart';

import 'impl/class_declarations_macro.dart';

@ClassDeclarationsDeclareInType('`int` get x => 3;')
class A {}

@ClassDeclarationsDeclareInLibrary('`int` get y => 4;')
class B {}

void main() {
  Expect.equals(A().x, 3);
  Expect.equals(y, 4);
}
