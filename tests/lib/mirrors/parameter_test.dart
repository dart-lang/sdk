// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Test of [ParameterMirror]. */
library test.parameter_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';
import 'stringify.dart';

class B {
  B();
  B.foo(int x);
  B.bar(int z, x);

  // TODO(6490): Currently only supported by the VM.
  B.baz(final int x, int y, final int z);
  B.qux(int x, [int y = 3 + 1]);
  B.quux(int x, {String str = "foo"});
  B.corge({int x = 3 * 17, String str = "bar"});

  var _x;
  get x => _x;
  set x(final value) {
    _x = value;
  }

  grault([int x = 0]) {}
  garply({int y = 0}) {}
  waldo(int z) {}
}

class C<S extends int, T> {
  // TODO(6490): Currently only supported by the VM.
  foo(int a, S b) => b;
  bar(S a, T b, num c) {}
}

main() {
  ClassMirror cm = reflectClass(B);
  var constructors = new Map<Symbol, MethodMirror>();
  cm.declarations.forEach((k, v) {
    if (v is MethodMirror && v.isConstructor) constructors[k] = v;
  });

  List<Symbol> constructorKeys = [
    #B,
    #B.bar,
    #B.baz,
    #B.foo,
    #B.quux,
    #B.qux,
    #B.corge,
  ];
  Expect.setEquals(constructorKeys, constructors.keys);

  MethodMirror unnamedConstructor = constructors[#B] as MethodMirror;
  expect('Method(s(B) in s(B), constructor)', unnamedConstructor);
  expect('[]', unnamedConstructor.parameters);
  expect(
    'Class(s(B) in s(test.parameter_test), top-level)',
    unnamedConstructor.returnType,
  );

  MethodMirror fooConstructor = constructors[#B.foo] as MethodMirror;
  expect('Method(s(B.foo) in s(B), constructor)', fooConstructor);
  expect(
    '[Parameter(s(x) in s(B.foo),'
    ' type = Class(s(int) in s(dart.core), top-level))]',
    fooConstructor.parameters,
  );
  expect(
    'Class(s(B) in s(test.parameter_test), top-level)',
    fooConstructor.returnType,
  );

  MethodMirror barConstructor = constructors[#B.bar] as MethodMirror;
  expect('Method(s(B.bar) in s(B), constructor)', barConstructor);
  expect(
    '[Parameter(s(z) in s(B.bar),'
    ' type = Class(s(int) in s(dart.core), top-level)), '
    'Parameter(s(x) in s(B.bar),'
    ' type = Type(s(dynamic), top-level))]',
    barConstructor.parameters,
  );
  expect(
    'Class(s(B) in s(test.parameter_test), top-level)',
    barConstructor.returnType,
  );

  MethodMirror bazConstructor = constructors[#B.baz] as MethodMirror;
  expect('Method(s(B.baz) in s(B), constructor)', bazConstructor);
  expect(
    '[Parameter(s(x) in s(B.baz), final,'
    ' type = Class(s(int) in s(dart.core), top-level)), '
    'Parameter(s(y) in s(B.baz),'
    ' type = Class(s(int) in s(dart.core), top-level)), '
    'Parameter(s(z) in s(B.baz), final,'
    ' type = Class(s(int) in s(dart.core), top-level))]',
    bazConstructor.parameters,
  );
  expect(
    'Class(s(B) in s(test.parameter_test), top-level)',
    bazConstructor.returnType,
  );

  MethodMirror quxConstructor = constructors[#B.qux] as MethodMirror;
  expect('Method(s(B.qux) in s(B), constructor)', quxConstructor);
  expect(
    '[Parameter(s(x) in s(B.qux),'
    ' type = Class(s(int) in s(dart.core), top-level)), '
    'Parameter(s(y) in s(B.qux), optional,'
    ' value = Instance(value = 4),'
    ' type = Class(s(int) in s(dart.core), top-level))]',
    quxConstructor.parameters,
  );
  expect(
    'Class(s(B) in s(test.parameter_test), top-level)',
    quxConstructor.returnType,
  );

  MethodMirror quuxConstructor = constructors[#B.quux] as MethodMirror;
  expect('Method(s(B.quux) in s(B), constructor)', quuxConstructor);
  expect(
    '[Parameter(s(x) in s(B.quux),'
    ' type = Class(s(int) in s(dart.core), top-level)), '
    'Parameter(s(str) in s(B.quux), optional, named,'
    ' value = Instance(value = foo),'
    ' type = Class(s(String) in s(dart.core), top-level))]',
    quuxConstructor.parameters,
  );
  expect(
    'Class(s(B) in s(test.parameter_test), top-level)',
    quuxConstructor.returnType,
  );

  MethodMirror corgeConstructor = constructors[#B.corge] as MethodMirror;
  expect('Method(s(B.corge) in s(B), constructor)', corgeConstructor);
  expect(
    '[Parameter(s(x) in s(B.corge), optional, named,'
    ' value = Instance(value = 51),'
    ' type = Class(s(int) in s(dart.core), top-level)), '
    'Parameter(s(str) in s(B.corge), optional, named,'
    ' value = Instance(value = bar),'
    ' type = Class(s(String) in s(dart.core), top-level))]',
    corgeConstructor.parameters,
  );
  expect(
    'Class(s(B) in s(test.parameter_test), top-level)',
    corgeConstructor.returnType,
  );

  MethodMirror xGetter = cm.declarations[#x] as MethodMirror;
  expect('Method(s(x) in s(B), getter)', xGetter);
  expect('[]', xGetter.parameters);

  MethodMirror xSetter = cm.declarations[const Symbol('x=')] as MethodMirror;
  expect('Method(s(x=) in s(B), setter)', xSetter);
  expect(
    '[Parameter(s(value) in s(x=), final,'
    ' type = Type(s(dynamic), top-level))]',
    xSetter.parameters,
  );

  MethodMirror grault = cm.declarations[#grault] as MethodMirror;
  expect('Method(s(grault) in s(B))', grault);
  expect(
    '[Parameter(s(x) in s(grault), optional, value = Instance(value = 0),'
    ' type = Class(s(int) in s(dart.core), top-level))]',
    grault.parameters,
  );
  expect('Instance(value = 0)', grault.parameters[0].defaultValue);

  MethodMirror garply = cm.declarations[#garply] as MethodMirror;
  expect('Method(s(garply) in s(B))', garply);
  expect(
    '[Parameter(s(y) in s(garply), optional, named, value = Instance(value = 0),'
    ' type = Class(s(int) in s(dart.core), top-level))]',
    garply.parameters,
  );
  expect('Instance(value = 0)', garply.parameters[0].defaultValue);

  MethodMirror waldo = cm.declarations[#waldo] as MethodMirror;
  expect('Method(s(waldo) in s(B))', waldo);
  expect(
    '[Parameter(s(z) in s(waldo),'
    ' type = Class(s(int) in s(dart.core), top-level))]',
    waldo.parameters,
  );
  expect('<null>', waldo.parameters[0].defaultValue);

  cm = reflectClass(C);

  MethodMirror fooInC = cm.declarations[#foo] as MethodMirror;
  expect('Method(s(foo) in s(C))', fooInC);

  MethodMirror barInC = cm.declarations[#bar] as MethodMirror;
  expect('Method(s(bar) in s(C))', barInC);
}
