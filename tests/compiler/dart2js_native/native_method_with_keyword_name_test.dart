// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

// Make sure we can have a native with a name that is a JavaScript keyword.

@Native("A")
class A {
  int delete() native;
}

A makeA() native { return new A(); }

void setup() native """
function A() {}
A.prototype.delete = function() { return 87; };

makeA = function(){return new A;};
""";


main() {
  setup();

  var a = makeA();
  Expect.equals(87, a.delete());
  A aa = a;
  Expect.equals(87, aa.delete());
}
