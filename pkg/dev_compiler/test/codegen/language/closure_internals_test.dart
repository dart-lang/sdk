// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C {
  foo() => 123;
}

main() {
  var f = new C().foo;
  Expect.throws(() => f.target, (e) => e is NoSuchMethodError);
  Expect.throws(() => f.self, (e) => e is NoSuchMethodError);
  Expect.throws(() => f.receiver, (e) => e is NoSuchMethodError);
}
