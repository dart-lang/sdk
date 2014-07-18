// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

@Native("A")
class A {}
makeA() native;

void setup() native """
function A() {}
makeA = function(){return new A;};
""";


main() {
  setup();
  var a = makeA();
  Expect.isTrue(a == a);
  Expect.isTrue(identical(a, a));

  Expect.isFalse(a == makeA());
  Expect.isFalse(identical(a, makeA()));
}
