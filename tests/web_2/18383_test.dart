// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Regression test for http://dartbug.com/18383

import "package:expect/expect.dart";

class F {
  call() => (x) => new G(x.toInt());
}

class G {
  var z;
  G(this.z);
  foo() => '$this.foo';
  toString() => 'G($z)';
}

main() {
  var f = new F();
  var m = f();
  Expect.equals(m(66).foo(), "G(66).foo");
}
