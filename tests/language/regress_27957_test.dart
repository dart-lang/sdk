// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'regress_27957_lib1.dart' as s1;
import 'regress_27957_lib2.dart' as s2;

class Mixin {}

class C1 = s1.Superclass with Mixin;
class C2 = s2.Superclass with Mixin;

main() {
  var c1 = new C1(), c2 = new C2();
  Expect.equals(1, c1.m());
  Expect.equals(2, c2.m());
}
