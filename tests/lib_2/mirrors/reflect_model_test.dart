// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.reflect_model_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'model.dart';
import 'stringify.dart';

variablesOf(ClassMirror cm) {
  var result = new Map();
  cm.declarations.forEach((k, v) {
    if (v is VariableMirror) result[k] = v;
  });
  return result;
}

gettersOf(ClassMirror cm) {
  var result = new Map();
  cm.declarations.forEach((k, v) {
    if (v is MethodMirror && v.isGetter) result[k] = v;
  });
  return result;
}

settersOf(ClassMirror cm) {
  var result = new Map();
  cm.declarations.forEach((k, v) {
    if (v is MethodMirror && v.isSetter) result[k] = v;
  });
  return result;
}

methodsOf(ClassMirror cm) {
  var result = new Map();
  cm.declarations.forEach((k, v) {
    if (v is MethodMirror && v.isRegularMethod) result[k] = v;
  });
  return result;
}

main() {
  var unnamed = new Symbol('');
  var field = new Symbol('field');
  var instanceMethod = new Symbol('instanceMethod');
  var accessor = new Symbol('accessor');
  var aMethod = new Symbol('aMethod');
  var bMethod = new Symbol('bMethod');
  var cMethod = new Symbol('cMethod');

  var aClass = reflectClass(A);
  var bClass = reflectClass(B);
  var cClass = reflectClass(C);
  var a = aClass.newInstance(unnamed, []);
  var b = bClass.newInstance(unnamed, []);
  var c = cClass.newInstance(unnamed, []);

  expect('{field: Variable(s(field) in s(A))}', variablesOf(aClass));
  expect('{}', variablesOf(bClass));
  expect('{}', variablesOf(cClass));

  Expect.isNull(a.getField(field).reflectee);
  Expect.equals('B:get field', b.getField(field).reflectee);
  Expect.equals('B:get field', c.getField(field).reflectee);

  Expect.equals(42, a.setField(field, 42).reflectee);
  Expect.equals(87, b.setField(field, 87).reflectee);
  Expect.equals(89, c.setField(field, 89).reflectee);

  Expect.equals(42, a.getField(field).reflectee);
  Expect.equals('B:get field', b.getField(field).reflectee);
  Expect.equals('B:get field', c.getField(field).reflectee);
  Expect.equals(89, fieldC);

  expect(
      '{accessor: Method(s(accessor) in s(A), getter)'
      '}',
      gettersOf(aClass));
  expect(
      '{accessor: Method(s(accessor) in s(B), getter)'
      ', field: Method(s(field) in s(B), getter)}',
      gettersOf(bClass));
  expect('{accessor: Method(s(accessor) in s(C), getter)}', gettersOf(cClass));

  expect(
      '{accessor=: Method(s(accessor=) in s(A), setter)'
      '}',
      settersOf(aClass));
  expect(
      '{accessor=: Method(s(accessor=) in s(B), setter)}', settersOf(bClass));
  expect(
      '{accessor=: Method(s(accessor=) in s(C), setter)'
      ', field=: Method(s(field=) in s(C), setter)}',
      settersOf(cClass));

  Expect.equals('A:instanceMethod(7)', a.invoke(instanceMethod, [7]).reflectee);
  Expect.equals('B:instanceMethod(9)', b.invoke(instanceMethod, [9]).reflectee);
  Expect.equals(
      'C:instanceMethod(13)', c.invoke(instanceMethod, [13]).reflectee);

  expect(
      '{aMethod: Method(s(aMethod) in s(A))'
      ', instanceMethod: Method(s(instanceMethod) in s(A))}',
      methodsOf(aClass));

  expect(
      '{bMethod: Method(s(bMethod) in s(B))'
      ', instanceMethod: Method(s(instanceMethod) in s(B))}',
      methodsOf(bClass));
  expect(
      '{cMethod: Method(s(cMethod) in s(C))'
      ', instanceMethod: Method(s(instanceMethod) in s(C))}',
      methodsOf(cClass));

  Expect.equals('A:get accessor', a.getField(accessor).reflectee);
  Expect.equals('B:get accessor', b.getField(accessor).reflectee);
  Expect.equals('C:get accessor', c.getField(accessor).reflectee);

  Expect.equals('foo', a.setField(accessor, 'foo').reflectee);
  Expect.equals('bar', b.setField(accessor, 'bar').reflectee);
  Expect.equals('baz', c.setField(accessor, 'baz').reflectee);

  Expect.equals('foo', accessorA);
  Expect.equals('bar', accessorB);
  Expect.equals('baz', accessorC);

  Expect.equals('aMethod', a.invoke(aMethod, []).reflectee);
  Expect.equals('aMethod', b.invoke(aMethod, []).reflectee);
  Expect.equals('aMethod', c.invoke(aMethod, []).reflectee);

  Expect.throwsNoSuchMethodError(() => a.invoke(bMethod, []));
  Expect.equals('bMethod', b.invoke(bMethod, []).reflectee);
  Expect.equals('bMethod', c.invoke(bMethod, []).reflectee);

  Expect.throwsNoSuchMethodError(() => a.invoke(cMethod, []));
  Expect.throwsNoSuchMethodError(() => b.invoke(cMethod, []));
  Expect.equals('cMethod', c.invoke(cMethod, []).reflectee);
}
