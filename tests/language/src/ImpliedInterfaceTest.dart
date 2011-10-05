// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class BaseClass {
  var foo;
  BaseClass() { foo = 0; }
  toString() => "BaseClass";
}

class ImplementsClass implements BaseClass {
  ImplementsClass() {}
}

interface ExtendsClass extends BaseClass {}

class ImplementsExtendsClass implements ExtendsClass {
  ImplementsExtendsClass() {}
}

main() {
  ImplementsClass c1 = new ImplementsClass();
  ImplementsExtendsClass c2 = new ImplementsExtendsClass();
  if (false) {
    // Verify we don't inherit the field from BaseClass
    Expect.equals(0, c1.foo); // 01: compile-time error
    Expect.equals(0, c2.foo); // 02: compile-time error
  }
  Expect.equals(true, c1 is BaseClass);
  Expect.equals(true, c1 is !ExtendsClass);
  Expect.equals(true, c2 is BaseClass);
  Expect.equals(true, c2 is ExtendsClass);
  Expect.equals(true, c2 is !ImplementsClass);
  Expect.equals("BaseClass", "${new BaseClass()}");

  // Verify we don't inherit toString from BaseClass
  Expect.equals("${new Object()}", "${c1}");
  Expect.equals("${new Object()}", "${c2}");
}
