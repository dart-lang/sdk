// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.declarations_model;

var libraryVariable;
get libraryGetter => null;
set librarySetter(x) => x;
libraryMethod() => null;

typedef bool Predicate(dynamic);

abstract class Interface<I> {
  operator /(x) => null;

  var interfaceInstanceVariable;
  get interfaceInstanceGetter;
  set interfaceInstanceSetter(x);
  interfaceInstanceMethod();

  static var interfaceStaticVariable;
  static get interfaceStaticGetter => null;
  static set interfaceStaticSetter(x) => x;
  static interfaceStaticMethod() => null;
}

class Superclass<S> {
  operator -(x) => null;

  var inheritedInstanceVariable;
  get inheritedInstanceGetter => null;
  set inheritedInstanceSetter(x) => x;
  inheritedInstanceMethod() => null;

  static var inheritedStaticVariable;
  static get inheritedStaticGetter => null;
  static set inheritedStaticSetter(x) => x;
  static inheritedStaticMethod() => null;

  Superclass.inheritedGenerativeConstructor(this.inheritedInstanceVariable);
  Superclass.inheritedRedirectingConstructor(x)
      : this.inheritedGenerativeConstructor(x * 2);
  factory Superclass.inheritedNormalFactory(y) =>
      new Superclass.inheritedRedirectingConstructor(y * 3);
  factory Superclass.inheritedRedirectingFactory(z) =
      Superclass<S>.inheritedNormalFactory;
}

abstract class Class<C> extends Superclass<C> implements Interface<C> {
  operator +(x) => null;

  abstractMethod();

  var instanceVariable;
  get instanceGetter => null;
  set instanceSetter(x) => x;
  instanceMethod() => null;

  static var staticVariable;
  static get staticGetter => null;
  static set staticSetter(x) => x;
  static staticMethod() => null;

  Class.generativeConstructor(this.instanceVariable)
      : super.inheritedGenerativeConstructor(0);
  Class.redirectingConstructor(x) : this.generativeConstructor(x * 2);
  factory Class.normalFactory(y) => new ConcreteClass(y * 3);
  factory Class.redirectingFactory(z) = Class<C>.normalFactory;
}

// This is just here as a target of Class's factories to appease the analyzer.
class ConcreteClass<CC> extends Class<CC> {
  abstractMethod() {}

  operator /(x) => null;

  var interfaceInstanceVariable;
  get interfaceInstanceGetter => null;
  set interfaceInstanceSetter(x) => null;
  interfaceInstanceMethod() => null;

  ConcreteClass(x) : super.generativeConstructor(x);
}
