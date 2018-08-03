// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library private_super_constructor_test;

import 'private_super_constructor_lib.dart';

class C extends B {
  C() : super._foo(); //# 01: compile-time error
}

main() => new C();
