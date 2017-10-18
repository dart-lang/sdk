// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for http://dartbug.com/22723.

import "package:expect/expect.dart";

class A {
  final x;

  @NoInline()
  A({this.x: "foo"}) {
    Expect.equals("foo", x.toString());
  }
}

class C extends A {
  C(foobar) {}
}

main() {
  var c = new C(499);
  Expect.equals("foo", c.x.toString());
}
