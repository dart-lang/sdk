// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 11891.

import "package:expect/expect.dart";
import "mixin_prefix_lib.dart";

class A extends Object with MixinClass {
  String baz() => bar();
}

void main() {
  var a = new A();
  Expect.equals('{"a":1}', a.baz());
}
