// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library a;

import 'private_clash_lib.dart' as lib;
import 'package:expect/expect.dart';

class A extends lib.B {
  var _b$_c$ = 100; // With library prefix: _a$_b$_c$

  getValueB() {
    try {} catch (e) {} // no inline
    return this._b$_c$;
  }
}

main() {
  A a = new A();
  Expect.equals(110, a.getValueA() + a.getValueB());
}
