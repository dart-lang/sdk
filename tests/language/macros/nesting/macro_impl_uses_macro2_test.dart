// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--enable-experiment=macros

import 'package:expect/expect.dart';

import 'impl/declare_count2_macro.dart';

@DeclareCount2()
class A {}

void main() {
  Expect.equals(A().count, 2);
}
