// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Intercepted members need to be accessed in a different way than normal
// members. In this test the native class A (thus being intercepted) has a
// member "foo", that is final. Therefore only the getter needs to be
// intercepted. Dart2js had a bug where it used the intercepted
// calling-convention for parts of the compiler, and the non-intercepted
// convention for others, making this fail.

import "package:expect/expect.dart";
import "dart:_js_helper";
import "dart:mirrors";

@Native("A")
class A {
  final foo;
}

class B {
  String foo;
}

main() {
  var b = new B();
  reflect(b).setField(new Symbol("foo"), "bar");
  Expect.equals("bar", b.foo);
}
