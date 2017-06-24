// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test various conditions around instantiating an abstract class.

// From The Dart Programming Language Specification, 11.11.1 "New":
//   If q is a constructor of an abstract class then an
//   AbstractClassInstantiation- Error is thrown.

abstract class Interface {
  void foo(); //# 03: static type warning
}

abstract class AbstractClass {
  toString() => 'AbstractClass';
}

class ConcreteSubclass extends AbstractClass {
  toString() => 'ConcreteSubclass';
}

class NonAbstractClass implements Interface {
  toString() => 'NonAbstractClass';
}

Interface interface() => new Interface(); //# 01: static type warning

AbstractClass abstractClass() => new AbstractClass(); //# 02: static type warning

bool isAbstractClassInstantiationError(e) {
  return e is AbstractClassInstantiationError;
}

void main() {
  Expect.throws(interface, isAbstractClassInstantiationError, //     //# 01: continued
                "expected AbstractClassInstantiationError"); //      //# 01: continued
  Expect.throws(abstractClass, isAbstractClassInstantiationError, // //# 02: continued
                "expected AbstractClassInstantiationError"); //      //# 02: continued
  Expect.stringEquals('ConcreteSubclass', '${new ConcreteSubclass()}');
  Expect.stringEquals('NonAbstractClass', '${new NonAbstractClass()}');
}
