// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test operators.
library test.operator_test;

@MirrorsUsed(targets: "test.operator_test")
import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'stringify.dart';

class Foo {
  Foo operator ~() {}
  Foo operator -() {}

  bool operator ==(a) {}
  Foo operator [](int a) {}
  Foo operator *(Foo a) {}
  Foo operator /(Foo a) {}
  Foo operator %(Foo a) {}
  Foo operator ~/(Foo a) {}
  Foo operator +(Foo a) {}
  Foo operator <<(Foo a) {}
  Foo operator >>(Foo a) {}
  Foo operator >=(Foo a) {}
  Foo operator >(Foo a) {}
  Foo operator <=(Foo a) {}
  Foo operator <(Foo a) {}
  Foo operator &(Foo a) {}
  Foo operator ^(Foo a) {}
  Foo operator |(Foo a) {}
  Foo operator -(Foo a) {}

  // TODO(ahe): use void when dart2js reifies that type.
  operator []=(int a, Foo b) {}
}

void main() {
  ClassMirror cls = reflectClass(Foo);
  var operators = new Map<Symbol, MethodMirror>();
  var operatorParameters = new Map<Symbol, List>();
  var returnTypes = new Map<Symbol, Mirror>();
  for (MethodMirror method in cls.declarations.values
      .where((d) => d is MethodMirror && !d.isConstructor)) {
    Expect.isTrue(method.isRegularMethod);
    Expect.isTrue(method.isOperator);
    Expect.isFalse(method.isGetter);
    Expect.isFalse(method.isSetter);
    Expect.isFalse(method.isAbstract);
    operators[method.simpleName] = method;
    operatorParameters[method.simpleName] = method.parameters;
    returnTypes[method.simpleName] = method.returnType;
  }
  expect(OPERATORS, operators);
  expect(PARAMETERS, operatorParameters);
  expect(RETURN_TYPES, returnTypes);
}

const String OPERATORS = '{'
    '%: Method(s(%) in s(Foo)), '
    '&: Method(s(&) in s(Foo)), '
    '*: Method(s(*) in s(Foo)), '
    '+: Method(s(+) in s(Foo)), '
    '-: Method(s(-) in s(Foo)), '
    '/: Method(s(/) in s(Foo)), '
    '<: Method(s(<) in s(Foo)), '
    '<<: Method(s(<<) in s(Foo)), '
    '<=: Method(s(<=) in s(Foo)), '
    '==: Method(s(==) in s(Foo)), '
    '>: Method(s(>) in s(Foo)), '
    '>=: Method(s(>=) in s(Foo)), '
    '>>: Method(s(>>) in s(Foo)), '
    '[]: Method(s([]) in s(Foo)), '
    '[]=: Method(s([]=) in s(Foo)), '
    '^: Method(s(^) in s(Foo)), '
    'unary-: Method(s(unary-) in s(Foo)), '
    '|: Method(s(|) in s(Foo)), '
    '~: Method(s(~) in s(Foo)), '
    '~/: Method(s(~/) in s(Foo))'
    '}';

const String DYNAMIC = 'Type(s(dynamic), top-level)';

const String FOO = 'Class(s(Foo) in s(test.operator_test), top-level)';

const String INT = 'Class(s(int) in s(dart.core), top-level)';

const String BOOL = 'Class(s(bool) in s(dart.core), top-level)';

const String PARAMETERS = '{'
    '%: [Parameter(s(a) in s(%), type = $FOO)], '
    '&: [Parameter(s(a) in s(&), type = $FOO)], '
    '*: [Parameter(s(a) in s(*), type = $FOO)], '
    '+: [Parameter(s(a) in s(+), type = $FOO)], '
    '-: [Parameter(s(a) in s(-), type = $FOO)], '
    '/: [Parameter(s(a) in s(/), type = $FOO)], '
    '<: [Parameter(s(a) in s(<), type = $FOO)], '
    '<<: [Parameter(s(a) in s(<<), type = $FOO)], '
    '<=: [Parameter(s(a) in s(<=), type = $FOO)], '
    '==: [Parameter(s(a) in s(==), type = $DYNAMIC)], '
    '>: [Parameter(s(a) in s(>), type = $FOO)], '
    '>=: [Parameter(s(a) in s(>=), type = $FOO)], '
    '>>: [Parameter(s(a) in s(>>), type = $FOO)], '
    '[]: [Parameter(s(a) in s([]), type = $INT)], '
    '[]=: [Parameter(s(a) in s([]=), type = $INT), '
    'Parameter(s(b) in s([]=), type = $FOO)], '
    '^: [Parameter(s(a) in s(^), type = $FOO)], '
    'unary-: [], '
    '|: [Parameter(s(a) in s(|), type = $FOO)], '
    '~: [], '
    '~/: [Parameter(s(a) in s(~/), type = $FOO)]'
    '}';

const String RETURN_TYPES = '{'
    '%: $FOO, '
    '&: $FOO, '
    '*: $FOO, '
    '+: $FOO, '
    '-: $FOO, '
    '/: $FOO, '
    '<: $FOO, '
    '<<: $FOO, '
    '<=: $FOO, '
    '==: $BOOL, '
    '>: $FOO, '
    '>=: $FOO, '
    '>>: $FOO, '
    '[]: $FOO, '
    '[]=: $DYNAMIC, '
    '^: $FOO, '
    'unary-: $FOO, '
    '|: $FOO, '
    '~: $FOO, '
    '~/: $FOO'
    '}';
