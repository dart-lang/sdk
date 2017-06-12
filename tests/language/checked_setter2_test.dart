// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that implicit setters in checked mode do a type check generic types.

import "package:expect/expect.dart";

class A {
  C<int> c;
}

class B extends A {}

class C<T> {}

var array = [new B()];

main() {
  array[0].c = new C();
  bool inCheckedMode = false;
  try {
    var i = 42;
    String a = i;
  } catch (e) {
    inCheckedMode = true;
  }
  if (inCheckedMode) {
    Expect.throws(() => array[0].c = new C<bool>(), (e) => e is TypeError);
  }
}
