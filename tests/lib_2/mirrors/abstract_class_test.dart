// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.abstract_class_test;

import 'dart:mirrors';
import 'package:expect/expect.dart';

void main() {
  testSimple();
  testFunctionType();
  testFakeFunction();
  testGeneric();
  testAnonMixinApplication();
  testNamedMixinApplication();
}

abstract class Foo {
  foo();
}

class Bar extends Foo {
  foo() {}
}

testSimple() {
  Expect.isTrue(reflectClass(Foo).isAbstract);
  Expect.isFalse(reflectClass(Bar).isAbstract);
  Expect.isTrue(reflect(new Bar()).type.superclass.isAbstract);
  Expect.isFalse(reflect(new Bar()).type.isAbstract);
}

void baz() {}

testFunctionType() {
  Expect.isFalse(reflect(baz).type.isAbstract);
}

abstract class FunctionFoo implements Function {
  call();
}

class FunctionBar extends FunctionFoo {
  call() {}
}

testFakeFunction() {
  Expect.isTrue(reflectClass(FunctionFoo).isAbstract);
  Expect.isFalse(reflectClass(FunctionBar).isAbstract);
  Expect.isTrue(reflect(new FunctionBar()).type.superclass.isAbstract);
  Expect.isFalse(reflect(new FunctionBar()).type.isAbstract);
}

abstract class GenericFoo<T> {
  T genericFoo();
}

class GenericBar<T> extends GenericFoo<T> {
  T genericFoo() {}
}

testGeneric() {
  // Unbound.
  Expect.isTrue(reflectClass(GenericFoo).isAbstract);
  Expect.isFalse(reflectClass(GenericBar).isAbstract);
  // Bound.
  Expect.isTrue(reflect(new GenericBar<int>()).type.superclass.isAbstract);
  Expect.isFalse(reflect(new GenericBar<int>()).type.isAbstract);
}

class S {}

abstract class M {
  mixinFoo();
}

abstract class MA extends S with M {}

class SubMA extends MA {
  mixinFoo() {}
}

class ConcreteMA extends S with M {
  mixinFoo() {}
}

class M2 {
  mixin2Foo() {}
}

abstract class MA2 extends S with M2 {
  mixinBar();
}

class SubMA2 extends MA2 {
  mixinBar() {}
}

class ConcreteMA2 extends S with M2 {
  mixin2Foo() {}
}

testAnonMixinApplication() {
  // Application is abstract.
  {
    // Mixin is abstract.
    Expect.isFalse(reflectClass(SubMA).isAbstract);
    Expect.isTrue(reflectClass(SubMA).superclass.isAbstract);
    Expect.isFalse(reflectClass(SubMA).superclass.superclass.isAbstract);
    Expect.isTrue(reflectClass(MA).isAbstract);
    Expect.isFalse(reflectClass(MA).superclass.isAbstract);

    // Mixin is concrete.
    Expect.isFalse(reflectClass(SubMA2).isAbstract);
    Expect.isTrue(reflectClass(SubMA2).superclass.isAbstract);
    Expect.isFalse(reflectClass(SubMA2).superclass.superclass.isAbstract);
    Expect.isTrue(reflectClass(MA2).isAbstract);
    Expect.isFalse(reflectClass(MA2).superclass.isAbstract);
  }

  // Application is concrete.
  {
    // Mixin is abstract.
    Expect.isFalse(reflectClass(ConcreteMA).isAbstract);
    Expect.isFalse(reflectClass(ConcreteMA).superclass.isAbstract);
    Expect.isFalse(reflectClass(ConcreteMA).superclass.superclass.isAbstract);

    // Mixin is concrete.
    Expect.isFalse(reflectClass(ConcreteMA2).isAbstract);
    Expect.isFalse(reflectClass(ConcreteMA2).superclass.isAbstract);
    Expect.isFalse(reflectClass(ConcreteMA2).superclass.superclass.isAbstract);
  }
}

abstract class NamedMA = S with M;

class SubNamedMA extends NamedMA {
  mixinFoo() {}
}

abstract class NamedMA2 = S with M2;

class SubNamedMA2 extends NamedMA2 {
  mixinFoo() {}
}

class ConcreteNamedMA2 = S with M2;

testNamedMixinApplication() {
  // Application is abstract.
  {
    // Mixin is abstract.
    Expect.isFalse(reflectClass(SubNamedMA).isAbstract);
    Expect.isTrue(reflectClass(SubNamedMA).superclass.isAbstract);
    Expect.isFalse(reflectClass(SubNamedMA).superclass.superclass.isAbstract);
    Expect.isTrue(reflectClass(NamedMA).isAbstract);
    Expect.isFalse(reflectClass(NamedMA).superclass.isAbstract);

    // Mixin is concrete.
    Expect.isFalse(reflectClass(SubNamedMA2).isAbstract);
    Expect.isTrue(reflectClass(SubNamedMA2).superclass.isAbstract);
    Expect.isFalse(reflectClass(SubNamedMA2).superclass.superclass.isAbstract);
    Expect.isTrue(reflectClass(NamedMA2).isAbstract);
    Expect.isFalse(reflectClass(NamedMA2).superclass.isAbstract);
  }

  // Application is concrete.
  {
    // Mixin is concrete.
    Expect.isFalse(reflectClass(ConcreteNamedMA2).isAbstract);
    Expect.isFalse(reflectClass(ConcreteNamedMA2).superclass.isAbstract);
  }
}
