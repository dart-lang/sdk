// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// When attempting to call a nonexistent constructor, check that a
// compile error is reported.

foo() {
  throw 'hest';
}

class A {
  A.foo(var x) {}
}

main() {
  new A.foo(42);


}
