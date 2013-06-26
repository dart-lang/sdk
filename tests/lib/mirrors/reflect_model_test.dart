// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.reflect_model_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'model.dart';

isNoSuchMethodError(e) => e is NoSuchMethodError;

name(DeclarationMirror mirror) {
  return (mirror == null) ? '<null>' : stringify(mirror.simpleName);
}

stringifyMap(Map map) {
  var buffer = new StringBuffer('{');
  bool first = true;
  for (String key in map.keys.map(MirrorSystem.getName).toList()..sort()) {
    if (!first) buffer.write(', ');
    first = false;
    buffer.write(key);
    buffer.write(': ');
    buffer.write(stringify(map[new Symbol(key)]));
  }
  return (buffer..write('}')).toString();
}

stringifySymbol(Symbol symbol) => 's(${MirrorSystem.getName(symbol)})';

writeDeclarationOn(DeclarationMirror mirror, StringBuffer buffer) {
  buffer.write(stringify(mirror.simpleName));
  if (mirror.owner != null) {
    buffer.write(' in ');
    buffer.write(name(mirror.owner));
  }
  if (mirror.isPrivate) buffer.write(', private');
  if (mirror.isTopLevel) buffer.write(', top-level');
}

stringifyVariable(VariableMirror variable) {
  var buffer = new StringBuffer('Variable(');
  writeDeclarationOn(variable, buffer);
  if (variable.isStatic) buffer.write(', static');
  if (variable.isFinal) buffer.write(', final');
  return (buffer..write(')')).toString();
}

stringifyMethod(MethodMirror method) {
  var buffer = new StringBuffer('Method(');
  writeDeclarationOn(method, buffer);
  if (method.isStatic) buffer.write(', static');
  if (method.isGetter) buffer.write(', getter');
  if (method.isSetter) buffer.write(', setter');
  if (method.isConstructor) buffer.write(', constructor');
  return (buffer..write(')')).toString();
}

stringify(value) {
  if (value is Map) return stringifyMap(value);
  if (value is VariableMirror) return stringifyVariable(value);
  if (value is MethodMirror) return stringifyMethod(value);
  if (value is Symbol) return stringifySymbol(value);
  if (value == null) return '<null>';
  throw 'Unexpected value: $value';
}

expect(expected, actual) => Expect.stringEquals(expected, stringify(actual));

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

  expect('{field: Variable(s(field) in s(A))}', aClass.variables);
  expect('{}', bClass.variables);
  expect('{}', cClass.variables);

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

  expect('{accessor: Method(s(accessor) in s(A), getter)'
         // TODO(ahe): Include instance field getters?
         ', field: Method(s(field) in s(A), getter)'
         '}',
         aClass.getters);
  expect('{accessor: Method(s(accessor) in s(B), getter)'
         ', field: Method(s(field) in s(B), getter)}',
         bClass.getters);
  expect('{accessor: Method(s(accessor) in s(C), getter)}',
         cClass.getters);

  expect('{accessor=: Method(s(accessor=) in s(A), setter)'
         // TODO(ahe): Include instance field setters?
         ', field=: Method(s(field=) in s(A), setter)'
         '}',
         aClass.setters);
  expect('{accessor=: Method(s(accessor=) in s(B), setter)}',
         bClass.setters);
  expect('{accessor=: Method(s(accessor=) in s(C), setter)'
         ', field=: Method(s(field=) in s(C), setter)}',
         cClass.setters);

  Expect.equals('A:instanceMethod(7)', a.invoke(instanceMethod, [7]).reflectee);
  Expect.equals('B:instanceMethod(9)', b.invoke(instanceMethod, [9]).reflectee);
  Expect.equals(
      'C:instanceMethod(13)', c.invoke(instanceMethod, [13]).reflectee);

  expect(
      '{aMethod: Method(s(aMethod) in s(A))'
      ', instanceMethod: Method(s(instanceMethod) in s(A))}',
      aClass.methods);

  expect(
      '{bMethod: Method(s(bMethod) in s(B))'
      ', instanceMethod: Method(s(instanceMethod) in s(B))}',
      bClass.methods);
  expect(
      '{cMethod: Method(s(cMethod) in s(C))'
      ', instanceMethod: Method(s(instanceMethod) in s(C))}',
      cClass.methods);

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

  Expect.throws(() { a.invoke(bMethod, []); }, isNoSuchMethodError);
  Expect.equals('bMethod', b.invoke(bMethod, []).reflectee);
  Expect.equals('bMethod', c.invoke(bMethod, []).reflectee);

  Expect.throws(() { a.invoke(cMethod, []); }, isNoSuchMethodError);
  Expect.throws(() { b.invoke(cMethod, []); }, isNoSuchMethodError);
  Expect.equals('cMethod', c.invoke(cMethod, []).reflectee);
}
