// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.declarations_test;

import 'dart:mirrors';
import 'package:expect/expect.dart';

import 'stringify.dart';
import 'declarations_model.dart' as declarations_model;

Set<DeclarationMirror> inheritedDeclarations(ClassMirror cm) {
  var decls = new Set<DeclarationMirror>();
  while (cm != null) {
    decls.addAll(cm.declarations.values);
    cm = cm.superclass;
  }
  return decls;
}

main() {
  ClassMirror cm = reflectClass(declarations_model.Class);

  Expect.setEquals([
    'Variable(s(_instanceVariable) in s(Class), private)',
    'Variable(s(_staticVariable) in s(Class), private, static)',
    'Variable(s(instanceVariable) in s(Class))',
    'Variable(s(staticVariable) in s(Class), static)'
  ], cm.declarations.values.where((dm) => dm is VariableMirror).map(stringify),
      'variables');

  Expect.setEquals(
      [
        'Method(s(_instanceGetter) in s(Class), private, getter)',
        'Method(s(_staticGetter) in s(Class), private, static, getter)',
        'Method(s(instanceGetter) in s(Class), getter)',
        'Method(s(staticGetter) in s(Class), static, getter)'
      ],
      cm.declarations.values
          .where((dm) => dm is MethodMirror && dm.isGetter)
          .map(stringify),
      'getters');

  Expect.setEquals(
      [
        'Method(s(_instanceSetter=) in s(Class), private, setter)',
        'Method(s(_staticSetter=) in s(Class), private, static, setter)',
        'Method(s(instanceSetter=) in s(Class), setter)',
        'Method(s(staticSetter=) in s(Class), static, setter)'
      ],
      cm.declarations.values
          .where((dm) => dm is MethodMirror && dm.isSetter)
          .map(stringify),
      'setters');

  // dart2js stops testing here.
  return; //# 01: ok

  Expect.setEquals(
      [
        'Method(s(+) in s(Class))',
        'Method(s(_instanceMethod) in s(Class), private)',
        'Method(s(_staticMethod) in s(Class), private, static)',
        'Method(s(abstractMethod) in s(Class), abstract)',
        'Method(s(instanceMethod) in s(Class))',
        'Method(s(staticMethod) in s(Class), static)'
      ],
      cm.declarations.values
          .where((dm) => dm is MethodMirror && dm.isRegularMethod)
          .map(stringify),
      'regular methods');

  Expect.setEquals(
      [
        'Method(s(Class._generativeConstructor) in s(Class), private, constructor)',
        'Method(s(Class._normalFactory) in s(Class), private, static, constructor)',
        'Method(s(Class._redirectingConstructor)'
            ' in s(Class), private, constructor)',
        'Method(s(Class._redirectingFactory)'
            ' in s(Class), private, static, constructor)',
        'Method(s(Class.generativeConstructor) in s(Class), constructor)',
        'Method(s(Class.normalFactory) in s(Class), static, constructor)',
        'Method(s(Class.redirectingConstructor) in s(Class), constructor)',
        'Method(s(Class.redirectingFactory) in s(Class), static, constructor)'
      ],
      cm.declarations.values
          .where((dm) => dm is MethodMirror && dm.isConstructor)
          .map(stringify),
      'constructors and factories');

  Expect.setEquals(
      [
        'Method(s(Class._normalFactory) in s(Class), private, static, constructor)',
        'Method(s(Class._redirectingFactory)'
            ' in s(Class), private, static, constructor)',
        'Method(s(Class.normalFactory) in s(Class), static, constructor)',
        'Method(s(Class.redirectingFactory) in s(Class), static, constructor)',
        'Method(s(_staticGetter) in s(Class), private, static, getter)',
        'Method(s(_staticMethod) in s(Class), private, static)',
        'Method(s(_staticSetter=) in s(Class), private, static, setter)',
        'Variable(s(_staticVariable) in s(Class), private, static)',
        'Method(s(staticGetter) in s(Class), static, getter)',
        'Method(s(staticMethod) in s(Class), static)',
        'Method(s(staticSetter=) in s(Class), static, setter)',
        'Variable(s(staticVariable) in s(Class), static)'
      ],
      cm.declarations.values
          .where((dm) => (dm as dynamic).isStatic)
          .map(stringify),
      'statics');

  Expect.setEquals(
      [
        'Method(s(+) in s(Class))',
        'TypeVariable(s(C) in s(Class),'
            ' upperBound = Class(s(Object) in s(dart.core), top-level))',
        'Method(s(Class._generativeConstructor) in s(Class), private, constructor)',
        'Method(s(Class._redirectingConstructor)'
            ' in s(Class), private, constructor)',
        'Method(s(Class.generativeConstructor) in s(Class), constructor)',
        'Method(s(Class.redirectingConstructor) in s(Class), constructor)',
        'Method(s(_instanceGetter) in s(Class), private, getter)',
        'Method(s(_instanceMethod) in s(Class), private)',
        'Method(s(_instanceSetter=) in s(Class), private, setter)',
        'Variable(s(_instanceVariable) in s(Class), private)',
        'Method(s(abstractMethod) in s(Class), abstract)',
        'Method(s(instanceGetter) in s(Class), getter)',
        'Method(s(instanceMethod) in s(Class))',
        'Method(s(instanceSetter=) in s(Class), setter)',
        'Variable(s(instanceVariable) in s(Class))'
      ],
      cm.declarations.values
          .where((dm) => !(dm as dynamic).isStatic)
          .map(stringify),
      'non-statics');

  Expect.setEquals(
      [
        'Method(s(+) in s(Class))',
        'TypeVariable(s(C) in s(Class),'
            ' upperBound = Class(s(Object) in s(dart.core), top-level))',
        'Method(s(Class.generativeConstructor) in s(Class), constructor)',
        'Method(s(Class.normalFactory) in s(Class), static, constructor)',
        'Method(s(Class.redirectingConstructor) in s(Class), constructor)',
        'Method(s(Class.redirectingFactory) in s(Class), static, constructor)',
        'Method(s(abstractMethod) in s(Class), abstract)',
        'Method(s(instanceGetter) in s(Class), getter)',
        'Method(s(instanceMethod) in s(Class))',
        'Method(s(instanceSetter=) in s(Class), setter)',
        'Variable(s(instanceVariable) in s(Class))',
        'Method(s(staticGetter) in s(Class), static, getter)',
        'Method(s(staticMethod) in s(Class), static)',
        'Method(s(staticSetter=) in s(Class), static, setter)',
        'Variable(s(staticVariable) in s(Class), static)'
      ],
      cm.declarations.values
          .where((dm) => !(dm as dynamic).isPrivate)
          .map(stringify),
      'public');

  Expect.setEquals([
    'Method(s(*) in s(Mixin))',
    'Method(s(+) in s(Class))',
    'Method(s(-) in s(Superclass))',
    'Method(s(==) in s(Object))',
    'TypeVariable(s(C) in s(Class),'
        ' upperBound = Class(s(Object) in s(dart.core), top-level))',
    'Method(s(Class.generativeConstructor) in s(Class), constructor)',
    'Method(s(Class.normalFactory) in s(Class), static, constructor)',
    'Method(s(Class.redirectingConstructor) in s(Class), constructor)',
    'Method(s(Class.redirectingFactory) in s(Class), static, constructor)',
    'Method(s(Object) in s(Object), constructor)',
    'TypeVariable(s(S) in s(Superclass),'
        ' upperBound = Class(s(Object) in s(dart.core), top-level))',
    'Method(s(Superclass.inheritedGenerativeConstructor)'
        ' in s(Superclass), constructor)',
    'Method(s(Superclass.inheritedNormalFactory)'
        ' in s(Superclass), static, constructor)',
    'Method(s(Superclass.inheritedRedirectingConstructor)'
        ' in s(Superclass), constructor)',
    'Method(s(Superclass.inheritedRedirectingFactory)'
        ' in s(Superclass), static, constructor)',
    'Method(s(abstractMethod) in s(Class), abstract)',
    'Method(s(hashCode) in s(Object), getter)',
    'Method(s(inheritedInstanceGetter) in s(Superclass), getter)',
    'Method(s(inheritedInstanceMethod) in s(Superclass))',
    'Method(s(inheritedInstanceSetter=) in s(Superclass), setter)',
    'Variable(s(inheritedInstanceVariable) in s(Superclass))',
    'Method(s(inheritedStaticGetter) in s(Superclass), static, getter)',
    'Method(s(inheritedStaticMethod) in s(Superclass), static)',
    'Method(s(inheritedStaticSetter=) in s(Superclass), static, setter)',
    'Variable(s(inheritedStaticVariable) in s(Superclass), static)',
    'Method(s(instanceGetter) in s(Class), getter)',
    'Method(s(instanceMethod) in s(Class))',
    'Method(s(instanceSetter=) in s(Class), setter)',
    'Variable(s(instanceVariable) in s(Class))',
    'Method(s(mixinInstanceGetter) in s(Mixin), getter)',
    'Method(s(mixinInstanceMethod) in s(Mixin))',
    'Method(s(mixinInstanceSetter=) in s(Mixin), setter)',
    'Variable(s(mixinInstanceVariable) in s(Mixin))',
    'Method(s(noSuchMethod) in s(Object))',
    'Method(s(runtimeType) in s(Object), getter)',
    'Method(s(staticGetter) in s(Class), static, getter)',
    'Method(s(staticMethod) in s(Class), static)',
    'Method(s(staticSetter=) in s(Class), static, setter)',
    'Variable(s(staticVariable) in s(Class), static)',
    'Method(s(test.declarations_model.Superclass'
        ' with test.declarations_model.Mixin.inheritedGenerativeConstructor)'
        ' in s(test.declarations_model.Superclass'
        ' with test.declarations_model.Mixin), constructor)',
    'Method(s(test.declarations_model.Superclass'
        ' with test.declarations_model.Mixin.inheritedRedirectingConstructor)'
        ' in s(test.declarations_model.Superclass'
        ' with test.declarations_model.Mixin), constructor)',
    'Method(s(toString) in s(Object))',
    'Variable(s(mixinStaticVariable) in s(Mixin), static)',
    'Method(s(mixinStaticGetter) in s(Mixin), static, getter)',
    'Method(s(mixinStaticSetter=) in s(Mixin), static, setter)',
    'Method(s(mixinStaticMethod) in s(Mixin), static)'
  ], inheritedDeclarations(cm).where((dm) => !dm.isPrivate).map(stringify),
      'transitive public');
  // The public members of Object should be the same in all implementations, so
  // we don't exclude Object here.

  Expect.setEquals([
    'Method(s(+) in s(Class))',
    'TypeVariable(s(C) in s(Class),'
        ' upperBound = Class(s(Object) in s(dart.core), top-level))',
    'Method(s(Class._generativeConstructor) in s(Class), private, constructor)',
    'Method(s(Class._normalFactory) in s(Class), private, static, constructor)',
    'Method(s(Class._redirectingConstructor)'
        ' in s(Class), private, constructor)',
    'Method(s(Class._redirectingFactory)'
        ' in s(Class), private, static, constructor)',
    'Method(s(Class.generativeConstructor) in s(Class), constructor)',
    'Method(s(Class.normalFactory) in s(Class), static, constructor)',
    'Method(s(Class.redirectingConstructor) in s(Class), constructor)',
    'Method(s(Class.redirectingFactory) in s(Class), static, constructor)',
    'Method(s(_instanceGetter) in s(Class), private, getter)',
    'Method(s(_instanceMethod) in s(Class), private)',
    'Method(s(_instanceSetter=) in s(Class), private, setter)',
    'Variable(s(_instanceVariable) in s(Class), private)',
    'Method(s(_staticGetter) in s(Class), private, static, getter)',
    'Method(s(_staticMethod) in s(Class), private, static)',
    'Method(s(_staticSetter=) in s(Class), private, static, setter)',
    'Variable(s(_staticVariable) in s(Class), private, static)',
    'Method(s(abstractMethod) in s(Class), abstract)',
    'Method(s(instanceGetter) in s(Class), getter)',
    'Method(s(instanceMethod) in s(Class))',
    'Method(s(instanceSetter=) in s(Class), setter)',
    'Variable(s(instanceVariable) in s(Class))',
    'Method(s(staticGetter) in s(Class), static, getter)',
    'Method(s(staticMethod) in s(Class), static)',
    'Method(s(staticSetter=) in s(Class), static, setter)',
    'Variable(s(staticVariable) in s(Class), static)'
  ], cm.declarations.values.map(stringify), 'declarations');

  Expect.setEquals(
      [
        'Method(s(*) in s(Mixin))',
        'Method(s(+) in s(Class))',
        'Method(s(-) in s(Superclass))',
        'TypeVariable(s(C) in s(Class),'
            ' upperBound = Class(s(Object) in s(dart.core), top-level))',
        'Method(s(Class._generativeConstructor) in s(Class), private, constructor)',
        'Method(s(Class._normalFactory) in s(Class), private, static, constructor)',
        'Method(s(Class._redirectingConstructor)'
            ' in s(Class), private, constructor)',
        'Method(s(Class._redirectingFactory)'
            ' in s(Class), private, static, constructor)',
        'Method(s(Class.generativeConstructor) in s(Class), constructor)',
        'Method(s(Class.normalFactory) in s(Class), static, constructor)',
        'Method(s(Class.redirectingConstructor) in s(Class), constructor)',
        'Method(s(Class.redirectingFactory) in s(Class), static, constructor)',
        'TypeVariable(s(S) in s(Superclass),'
            ' upperBound = Class(s(Object) in s(dart.core), top-level))',
        'Method(s(Superclass._inheritedGenerativeConstructor)'
            ' in s(Superclass), private, constructor)',
        'Method(s(Superclass._inheritedNormalFactory)'
            ' in s(Superclass), private, static, constructor)',
        'Method(s(Superclass._inheritedRedirectingConstructor)'
            ' in s(Superclass), private, constructor)',
        'Method(s(Superclass._inheritedRedirectingFactory)'
            ' in s(Superclass), private, static, constructor)',
        'Method(s(Superclass.inheritedGenerativeConstructor)'
            ' in s(Superclass), constructor)',
        'Method(s(Superclass.inheritedNormalFactory)'
            ' in s(Superclass), static, constructor)',
        'Method(s(Superclass.inheritedRedirectingConstructor)'
            ' in s(Superclass), constructor)',
        'Method(s(Superclass.inheritedRedirectingFactory)'
            ' in s(Superclass), static, constructor)',
        'Method(s(_inheritedInstanceGetter) in s(Superclass), private, getter)',
        'Method(s(_inheritedInstanceMethod) in s(Superclass), private)',
        'Method(s(_inheritedInstanceSetter=) in s(Superclass), private, setter)',
        'Variable(s(_inheritedInstanceVariable) in s(Superclass), private)',
        'Method(s(_inheritedStaticGetter)'
            ' in s(Superclass), private, static, getter)',
        'Method(s(_inheritedStaticMethod) in s(Superclass), private, static)',
        'Method(s(_inheritedStaticSetter=)'
            ' in s(Superclass), private, static, setter)',
        'Variable(s(_inheritedStaticVariable) in s(Superclass), private, static)',
        'Method(s(_instanceGetter) in s(Class), private, getter)',
        'Method(s(_instanceMethod) in s(Class), private)',
        'Method(s(_instanceSetter=) in s(Class), private, setter)',
        'Variable(s(_instanceVariable) in s(Class), private)',
        'Method(s(_mixinInstanceGetter) in s(Mixin), private, getter)',
        'Method(s(_mixinInstanceMethod) in s(Mixin), private)',
        'Method(s(_mixinInstanceSetter=) in s(Mixin), private, setter)',
        'Variable(s(_mixinInstanceVariable) in s(Mixin), private)',
        'Method(s(_staticGetter) in s(Class), private, static, getter)',
        'Method(s(_staticMethod) in s(Class), private, static)',
        'Method(s(_staticSetter=) in s(Class), private, static, setter)',
        'Variable(s(_staticVariable) in s(Class), private, static)',
        'Method(s(abstractMethod) in s(Class), abstract)',
        'Method(s(inheritedInstanceGetter) in s(Superclass), getter)',
        'Method(s(inheritedInstanceMethod) in s(Superclass))',
        'Method(s(inheritedInstanceSetter=) in s(Superclass), setter)',
        'Variable(s(inheritedInstanceVariable) in s(Superclass))',
        'Method(s(inheritedStaticGetter) in s(Superclass), static, getter)',
        'Method(s(inheritedStaticMethod) in s(Superclass), static)',
        'Method(s(inheritedStaticSetter=) in s(Superclass), static, setter)',
        'Variable(s(inheritedStaticVariable) in s(Superclass), static)',
        'Method(s(instanceGetter) in s(Class), getter)',
        'Method(s(instanceMethod) in s(Class))',
        'Method(s(instanceSetter=) in s(Class), setter)',
        'Variable(s(instanceVariable) in s(Class))',
        'Method(s(mixinInstanceGetter) in s(Mixin), getter)',
        'Method(s(mixinInstanceMethod) in s(Mixin))',
        'Method(s(mixinInstanceSetter=) in s(Mixin), setter)',
        'Variable(s(mixinInstanceVariable) in s(Mixin))',
        'Method(s(staticGetter) in s(Class), static, getter)',
        'Method(s(staticMethod) in s(Class), static)',
        'Method(s(staticSetter=) in s(Class), static, setter)',
        'Variable(s(staticVariable) in s(Class), static)',
        'Method(s(test.declarations_model.Superclass'
            ' with test.declarations_model.Mixin._inheritedGenerativeConstructor)'
            ' in s(test.declarations_model.Superclass'
            ' with test.declarations_model.Mixin), private, constructor)',
        'Method(s(test.declarations_model.Superclass'
            ' with test.declarations_model.Mixin._inheritedRedirectingConstructor)'
            ' in s(test.declarations_model.Superclass'
            ' with test.declarations_model.Mixin), private, constructor)',
        'Method(s(test.declarations_model.Superclass'
            ' with test.declarations_model.Mixin.inheritedGenerativeConstructor)'
            ' in s(test.declarations_model.Superclass'
            ' with test.declarations_model.Mixin), constructor)',
        'Method(s(test.declarations_model.Superclass'
            ' with test.declarations_model.Mixin.inheritedRedirectingConstructor)'
            ' in s(test.declarations_model.Superclass'
            ' with test.declarations_model.Mixin), constructor)',
        'Variable(s(mixinStaticVariable) in s(Mixin), static)',
        'Variable(s(_mixinStaticVariable) in s(Mixin), private, static)',
        'Method(s(mixinStaticGetter) in s(Mixin), static, getter)',
        'Method(s(mixinStaticSetter=) in s(Mixin), static, setter)',
        'Method(s(mixinStaticMethod) in s(Mixin), static)',
        'Method(s(_mixinStaticGetter) in s(Mixin), private, static, getter)',
        'Method(s(_mixinStaticSetter=) in s(Mixin), private, static, setter)',
        'Method(s(_mixinStaticMethod) in s(Mixin), private, static)'
      ],
      inheritedDeclarations(cm)
          .difference(reflectClass(Object).declarations.values.toSet())
          .map(stringify),
      'transitive less Object');
  // The private members of Object may vary across implementations, so we
  // exclude the declarations of Object in this test case.
}
