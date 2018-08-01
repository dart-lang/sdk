// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The removed language feature "interface injection" is now a syntax error.

import "package:expect/expect.dart";

abstract class S { }
class C { }
class C implements S;  //# 1: syntax error

main() {
  Expect.isFalse(new C() is S);
}
