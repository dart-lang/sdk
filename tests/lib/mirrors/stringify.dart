// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper methods for converting a [Mirror] to a [String].
library test.stringify;

import 'dart:mirrors';

import 'package:expect/expect.dart';

name(DeclarationMirror mirror) {
  return (mirror == null) ? '<null>' : stringify(mirror.simpleName);
}

stringifyMap(Map map) {
  var buffer = new StringBuffer();
  bool first = true;
  for (String key in map.keys.map(MirrorSystem.getName).toList()..sort()) {
    if (!first) buffer.write(', ');
    first = false;
    buffer.write(key);
    buffer.write(': ');
    buffer.write(stringify(map[new Symbol(key)]));
  }
  return '{$buffer}';
}

stringifyList(List list) {
  var buffer = new StringBuffer();
  bool first = true;
  for (String value in list.map(stringify)) {
    if (!first) buffer.write(', ');
    first = false;
    buffer.write(value);
  }
  return '[$buffer]';
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

writeVariableOn(VariableMirror variable, StringBuffer buffer) {
  writeDeclarationOn(variable, buffer);
  if (variable.isStatic) buffer.write(', static');
  if (variable.isFinal) buffer.write(', final');
}

stringifyVariable(VariableMirror variable) {
  var buffer = new StringBuffer();
  writeVariableOn(variable, buffer);
  return 'Variable($buffer)';
}

stringifyParameter(ParameterMirror parameter) {
  var buffer = new StringBuffer();
  writeVariableOn(parameter, buffer);
  if (parameter.isOptional) buffer.write(', optional');
  if (parameter.isNamed) buffer.write(', named');
  if (parameter.hasDefaultValue) {
    buffer.write(', value = ${stringify(parameter.defaultValue)}');
  }
  // TODO(ahe): Move to writeVariableOn.
  buffer.write(', type = ${stringifyType(parameter.type)}');
  return 'Parameter($buffer)';
}

stringifyType(TypeMirror type) {
  var buffer = new StringBuffer();
  writeDeclarationOn(type, buffer);
  return 'Type($buffer)';
}

stringifyMethod(MethodMirror method) {
  var buffer = new StringBuffer();
  writeDeclarationOn(method, buffer);
  if (method.isStatic) buffer.write(', static');
  if (method.isGetter) buffer.write(', getter');
  if (method.isSetter) buffer.write(', setter');
  if (method.isConstructor) buffer.write(', constructor');
  return 'Method($buffer)';
}

stringify(value) {
  if (value is Map) return stringifyMap(value);
  if (value is List) return stringifyList(value);
  if (value is ParameterMirror) return stringifyParameter(value);
  if (value is VariableMirror) return stringifyVariable(value);
  if (value is MethodMirror) return stringifyMethod(value);
  if (value is Symbol) return stringifySymbol(value);
  if (value is TypeMirror) return stringifyType(value);
  if (value == null) return '<null>';
  throw 'Unexpected value: $value';
}

expect(expected, actual) => Expect.stringEquals(expected, stringify(actual));
