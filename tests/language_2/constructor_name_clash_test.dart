// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'constructor_name_clash_lib.dart' as lib;

class A extends lib.A {
  A() {
    lib.global += 100;
    try {} catch (e) {} // no inline
  }
}

main() {
  new A();
  Expect.equals(110, lib.global);
}
