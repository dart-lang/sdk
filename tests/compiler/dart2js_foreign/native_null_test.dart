// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that parameters in native methods are not mangled. This test is needed
// until we change all libraries to using the JS foreign element.

@native("*A")
class A  {
  @native("return null;")
  returnNull();
  @native("return undefined;")
  returnUndefined();
  @native("return '';")
  returnEmptyString();
  @native("return 0;")
  returnZero();
}

@native A makeA();

@native("""
function A() {}
makeA = function(){return new A;};
""")
void setup();


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
