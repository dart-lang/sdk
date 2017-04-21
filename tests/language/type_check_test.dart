// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to remove the a B type check
// after an A type check, because it thought any subtype of A had to be B.

import "package:expect/expect.dart";

class A {}

class B extends A {}

main() {
  var a = [new A(), new B()];
  var b = a[0];
  b = b as A;
  Expect.throws(() => b as B, (e) => e is CastError);
}
