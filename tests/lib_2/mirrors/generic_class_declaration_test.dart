// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'package:expect/expect.dart';

import 'stringify.dart';

class A<T> {
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
}

main() {
  ClassMirror cm = reflect(new A<String>()).type;
  Expect.setEquals([
    'Variable(s(_instanceVariable) in s(A), private)',
    'Variable(s(_staticVariable) in s(A), private, static)',
    'Variable(s(instanceVariable) in s(A))',
    'Variable(s(staticVariable) in s(A), static)'
  ], cm.declarations.values.where((dm) => dm is VariableMirror).map(stringify),
      'variables');

  Expect.setEquals(
      [
        'Method(s(_instanceGetter) in s(A), private, getter)',
        'Method(s(_staticGetter) in s(A), private, static, getter)',
        'Method(s(instanceGetter) in s(A), getter)',
        'Method(s(staticGetter) in s(A), static, getter)'
      ],
      cm.declarations.values
          .where((dm) => dm is MethodMirror && dm.isGetter)
          .map(stringify),
      'getters');

  Expect.setEquals(
      [
        'Method(s(_instanceSetter=) in s(A), private, setter)',
        'Method(s(_staticSetter=) in s(A), private, static, setter)',
        'Method(s(instanceSetter=) in s(A), setter)',
        'Method(s(staticSetter=) in s(A), static, setter)'
      ],
      cm.declarations.values
          .where((dm) => dm is MethodMirror && dm.isSetter)
          .map(stringify),
      'setters');

  Expect.setEquals(
      [
        'Method(s(_instanceMethod) in s(A), private)',
        'Method(s(_staticMethod) in s(A), private, static)',
        'Method(s(instanceMethod) in s(A))',
        'Method(s(staticMethod) in s(A), static)'
      ],
      cm.declarations.values
          .where((dm) => dm is MethodMirror && dm.isRegularMethod)
          .map(stringify),
      'methods');

  Expect.setEquals(
      ['Method(s(A) in s(A), constructor)'],
      cm.declarations.values
          .where((dm) => dm is MethodMirror && dm.isConstructor)
          .map(stringify),
      'constructors');

  Expect.setEquals(
      [
        'TypeVariable(s(T) in s(A), upperBound = Class(s(Object) in '
            's(dart.core), top-level))'
      ],
      cm.declarations.values
          .where((dm) => dm is TypeVariableMirror)
          .map(stringify),
      'type variables');
}
