// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The removed language feature "interface injection" is now a syntax error.

import "package:expect/expect.dart";

abstract class S { }
abstract class I { }
abstract class I implements S;  //# 1: syntax error

class C implements I { }

main() {
  Expect.isFalse(new C() is S);
}
