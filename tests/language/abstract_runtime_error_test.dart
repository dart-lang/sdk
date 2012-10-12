// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test various conditions around instantiating an abstract class.

// From The Dart Programming Langauge Specification, 11.11.1 "New":
//   If q is a constructor of an abstract class then an
//   AbstractClassInstantiation- Error is thrown.


abstract class Interface {
  void foo();
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

Interface interface() => new Interface();

AbstractClass abstractClass() => new AbstractClass();

bool isAbstractClassInstantiationError(e) {
  return e is AbstractClassInstantiationError;
}

void main() {
  Expect.throws(interface, isAbstractClassInstantiationError,
                "expected AbstractClassInstantiationError");
  Expect.throws(abstractClass, isAbstractClassInstantiationError,
                "expected AbstractClassInstantiationError");
  Expect.stringEquals('ConcreteSubclass', '${new ConcreteSubclass()}');
  Expect.stringEquals('NonAbstractClass', '${new NonAbstractClass()}');
}
