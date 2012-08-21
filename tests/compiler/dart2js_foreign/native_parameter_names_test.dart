// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that parameters in native methods are not mangled. This test is needed
// until we change all libraries to using the JS foreign element.

@native("*A")
class A  {
  @native("return name;")
  foo(name);
  @native("return undefined;")
  bar(undefined);
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
  Expect.equals(42, a.foo(42));
  Expect.equals(42, a.bar(42));
}
