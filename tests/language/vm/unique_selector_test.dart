// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  _unique_method() => "foo";
  bar() => "A";
}

class B {
  noSuchMethod(invocation) => "nsm";
  bar() => "B";
}

confuse(x) {
  try {
    throw x;
  } catch (e) {
    return e;
  }
  return null;
}

main() {
  var a = confuse(new A());
  Expect.equals("foo", a._unique_method());
  Expect.equals("A", a.bar());

  var b = confuse(new B());
  Expect.equals("nsm", b._unique_method());
  Expect.equals("B", b.bar()); // Don't propagate type A to b.
}
