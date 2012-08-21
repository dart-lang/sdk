// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that parameters in native methods are not mangled. This test is needed
// until we change all libraries to using the JS foreign element.

class A native "*A" {
  returnNull() native "return null;";
  returnUndefined() native "return undefined;";
  returnEmptyString() native "return '';";
  returnZero() native "return 0;";
}

A makeA() native;

void setup() native """
function A() {}
makeA = function(){return new A;};
""";


main() {
  setup();
  A a = makeA();
  Expect.equals(null, a.returnNull());
  Expect.equals(null, a.returnUndefined());

  Expect.equals('', a.returnEmptyString());
  Expect.isTrue(a.returnEmptyString().isEmpty());
  Expect.isTrue(a.returnEmptyString() is String);

  Expect.isTrue(a.returnZero() is int);
  Expect.equals(0, a.returnZero());
}
