// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class BaseClass {
  var foo;
  BaseClass() {
    foo = 0;
  }
  toString() => "BaseClass";
}

/**
 * This class declaration causes an intentional type warning as it
 * isn't marked abstract. It is abstract because it doesn't
 * "implement" the field foo.
 */
class ImplementsClass implements BaseClass {
  ImplementsClass() {}
}

abstract class ExtendsClass implements BaseClass {}

/**
 * This class declaration causes an intentional type warning as it
 * isn't marked abstract. It is abstract because it doesn't
 * "implement" the field foo.
 */
class ImplementsExtendsClass implements ExtendsClass {
  ImplementsExtendsClass() {}
}

main() {
  ImplementsClass c1 = new ImplementsClass();
  ImplementsExtendsClass c2 = new ImplementsExtendsClass();
  try {
    c1.foo;
    Expect.fail('expected a NoSuchMethodError');
  } on NoSuchMethodError catch (ex) {
    // Expected error.
  }
  try {
    c2.foo;
    Expect.fail('expected a NoSuchMethodError');
  } on NoSuchMethodError catch (ex) {
    // Expected error.
  }
  Expect.equals(true, c1 is BaseClass);
  Expect.equals(true, c1 is! ExtendsClass);
  Expect.equals(true, c2 is BaseClass);
  Expect.equals(true, c2 is ExtendsClass);
  Expect.equals(true, c2 is! ImplementsClass);
  Expect.equals("BaseClass", "${new BaseClass()}");

  // Verify we don't inherit toString from BaseClass
  Expect.notEquals("BaseClass", "${c1}");
  Expect.notEquals("BaseClass", "${c2}");
}
