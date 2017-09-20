// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

abstract class S { }
abstract class I { }
abstract class I implements S;

class C implements I { }

main() {
  Expect.equals(true, new C() is S);
}
