// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.declarations_model;

var libraryVariable;
get libraryGetter => null;
set librarySetter(x) => x;
libraryMethod() => null;

var _libraryVariable;
get _libraryGetter => null;
set _librarySetter(x) => x;
_libraryMethod() => null;

typedef bool Predicate(dynamic);

abstract class Interface<I> {
  operator /(x) => null;

  var interfaceInstanceVariable;
  get interfaceInstanceGetter;
  set interfaceInstanceSetter(x);
  interfaceInstanceMethod();

  var _interfaceInstanceVariable;
  get _interfaceInstanceGetter;
  set _interfaceInstanceSetter(x);
  _interfaceInstanceMethod();

  static var interfaceStaticVariable;
  static get interfaceStaticGetter => null;
  static set interfaceStaticSetter(x) => x;
  static interfaceStaticMethod() => null;

  static var _interfaceStaticVariable;
  static get _interfaceStaticGetter => null;
  static set _interfaceStaticSetter(x) => x;
  static _interfaceStaticMethod() => null;
}

class Mixin<M> {
  operator *(x) => null;

  var mixinInstanceVariable;
  get mixinInstanceGetter => null;
  set mixinInstanceSetter(x) => x;
  mixinInstanceMethod() => null;

  var _mixinInstanceVariable;
  get _mixinInstanceGetter => null;
  set _mixinInstanceSetter(x) => x;
  _mixinInstanceMethod() => null;

  static var mixinStaticVariable;
  static get mixinStaticGetter => null;
  static set mixinStaticSetter(x) => x;
  static mixinStaticMethod() => null;

  static var _mixinStaticVariable;
  static get _mixinStaticGetter => null;
  static set _mixinStaticSetter(x) => x;
  static _mixinStaticMethod() => null;
}

class Superclass<S> {
  operator -(x) => null;

  var inheritedInstanceVariable;
  get inheritedInstanceGetter => null;
  set inheritedInstanceSetter(x) => x;
  inheritedInstanceMethod() => null;

  var _inheritedInstanceVariable;
  get _inheritedInstanceGetter => null;
  set _inheritedInstanceSetter(x) => x;
  _inheritedInstanceMethod() => null;

  static var inheritedStaticVariable;
  static get inheritedStaticGetter => null;
  static set inheritedStaticSetter(x) => x;
  static inheritedStaticMethod() => null;

  static var _inheritedStaticVariable;
  static get _inheritedStaticGetter => null;
  static set _inheritedStaticSetter(x) => x;
  static _inheritedStaticMethod() => null;

  Superclass.inheritedGenerativeConstructor(this.inheritedInstanceVariable);
  Superclass.inheritedRedirectingConstructor(x)
      : this.inheritedGenerativeConstructor(x * 2);
  factory Superclass.inheritedNormalFactory(y) =>
      new Superclass.inheritedRedirectingConstructor(y * 3);
  factory Superclass.inheritedRedirectingFactory(z) =
      Superclass<S>.inheritedNormalFactory;

  Superclass._inheritedGenerativeConstructor(this._inheritedInstanceVariable);
  Superclass._inheritedRedirectingConstructor(x)
      : this._inheritedGenerativeConstructor(x * 2);
  factory Superclass._inheritedNormalFactory(y) =>
      new Superclass._inheritedRedirectingConstructor(y * 3);
  factory Superclass._inheritedRedirectingFactory(z) =
      Superclass<S>._inheritedNormalFactory;
}

abstract class Class<C> extends Superclass<C>
    with Mixin<C>
    implements Interface<C> {
  operator +(x) => null;

  abstractMethod();

  var instanceVariable;
  get instanceGetter => null;
  set instanceSetter(x) => x;
  instanceMethod() => null;

  var _instanceVariable;
  get _instanceGetter => null;
  set _instanceSetter(x) => x;
  _instanceMethod() => null;

  static var staticVariable;
  static get staticGetter => null;
  static set staticSetter(x) => x;
  static staticMethod() => null;

  static var _staticVariable;
  static get _staticGetter => null;
  static set _staticSetter(x) => x;
  static _staticMethod() => null;

  Class.generativeConstructor(this.instanceVariable)
      : super.inheritedGenerativeConstructor(0);
  Class.redirectingConstructor(x) : this.generativeConstructor(x * 2);
  factory Class.normalFactory(y) => new ConcreteClass(y * 3);
  factory Class.redirectingFactory(z) = Class<C>.normalFactory;

  Class._generativeConstructor(this._instanceVariable)
      : super._inheritedGenerativeConstructor(0);
  Class._redirectingConstructor(x) : this._generativeConstructor(x * 2);
  factory Class._normalFactory(y) => new ConcreteClass(y * 3);
  factory Class._redirectingFactory(z) = Class<C>._normalFactory;
}

// This is just here as a target of Class's factories to appease the analyzer.
class ConcreteClass<CC> extends Class<CC> {
  abstractMethod() {}

  operator /(x) => null;

  var interfaceInstanceVariable;
  get interfaceInstanceGetter => null;
  set interfaceInstanceSetter(x) => null;
  interfaceInstanceMethod() => null;

  var _interfaceInstanceVariable;
  get _interfaceInstanceGetter => null;
  set _interfaceInstanceSetter(x) => null;
  _interfaceInstanceMethod() => null;

  ConcreteClass(x) : super.generativeConstructor(x);
}

class _PrivateClass {}
