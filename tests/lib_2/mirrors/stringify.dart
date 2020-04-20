// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper methods for converting a [Mirror] to a [String].
library test.stringify;

import 'dart:mirrors';

import 'package:expect/expect.dart';

String name(DeclarationMirror mirror) {
  return (mirror == null) ? '<null>' : stringify(mirror.simpleName);
}

String stringifyMap(Map map) {
  var buffer = new StringBuffer();
  bool first = true;
  var names = map.keys.map((s) => MirrorSystem.getName(s)).toList()..sort();
  for (String key in names) {
    if (!first) buffer.write(', ');
    first = false;
    buffer.write(key);
    buffer.write(': ');
    buffer.write(stringify(map[new Symbol(key)]));
  }
  return '{$buffer}';
}

String stringifyIterable(Iterable list) {
  var buffer = new StringBuffer();
  bool first = true;
  for (String value in list.map(stringify)) {
    if (!first) buffer.write(', ');
    first = false;
    buffer.write(value);
  }
  return '[$buffer]';
}

String stringifyInstance(InstanceMirror instance) {
  var buffer = new StringBuffer();
  if (instance.hasReflectee) {
    buffer.write('value = ${stringify(instance.reflectee)}');
  }
  return 'Instance(${buffer})';
}

String stringifySymbol(Symbol symbol) => 's(${MirrorSystem.getName(symbol)})';

void writeDeclarationOn(DeclarationMirror mirror, StringBuffer buffer) {
  buffer.write(stringify(mirror.simpleName));
  if (mirror.owner != null) {
    buffer.write(' in ');
    buffer.write(name(mirror.owner));
  }
  if (mirror.isPrivate) buffer.write(', private');
  if (mirror.isTopLevel) buffer.write(', top-level');
}

void writeVariableOn(VariableMirror variable, StringBuffer buffer) {
  writeDeclarationOn(variable, buffer);
  if (variable.isStatic) buffer.write(', static');
  if (variable.isFinal) buffer.write(', final');
}

String stringifyVariable(VariableMirror variable) {
  var buffer = new StringBuffer();
  writeVariableOn(variable, buffer);
  return 'Variable($buffer)';
}

String stringifyParameter(ParameterMirror parameter) {
  var buffer = new StringBuffer();
  writeVariableOn(parameter, buffer);
  if (parameter.isOptional) buffer.write(', optional');
  if (parameter.isNamed) buffer.write(', named');
  // TODO(6490): dart2js always returns false for hasDefaultValue.
  if (parameter.hasDefaultValue) {
    buffer.write(', value = ${stringify(parameter.defaultValue)}');
  }
  // TODO(ahe): Move to writeVariableOn.
  buffer.write(', type = ${stringify(parameter.type)}');
  return 'Parameter($buffer)';
}

String stringifyTypeVariable(TypeVariableMirror typeVariable) {
  var buffer = new StringBuffer();
  writeDeclarationOn(typeVariable, buffer);
  buffer.write(', upperBound = ${stringify(typeVariable.upperBound)}');
  return 'TypeVariable($buffer)';
}

String stringifyType(TypeMirror type) {
  var buffer = new StringBuffer();
  writeDeclarationOn(type, buffer);
  return 'Type($buffer)';
}

String stringifyClass(ClassMirror cls) {
  var buffer = new StringBuffer();
  writeDeclarationOn(cls, buffer);
  return 'Class($buffer)';
}

String stringifyMethod(MethodMirror method) {
  var buffer = new StringBuffer();
  writeDeclarationOn(method, buffer);
  if (method.isAbstract) buffer.write(', abstract');
  if (method.isSynthetic) buffer.write(', synthetic');
  if (method.isStatic) buffer.write(', static');
  if (method.isGetter) buffer.write(', getter');
  if (method.isSetter) buffer.write(', setter');
  if (method.isConstructor) buffer.write(', constructor');
  return 'Method($buffer)';
}

String stringifyDependencies(LibraryMirror l) {
  n(s) => s is Symbol ? MirrorSystem.getName(s) : s;
  int compareDep(a, b) {
    if (a.targetLibrary == b.targetLibrary) {
      if ((a.prefix != null) && (b.prefix != null)) {
        return n(a.prefix).compareTo(n(b.prefix));
      }
      return a.prefix == null ? 1 : -1;
    }
    return n(a.targetLibrary.simpleName)
        .compareTo(n(b.targetLibrary.simpleName));
  }

  int compareCom(a, b) => n(a.identifier).compareTo(n(b.identifier));
  int compareFirst(a, b) => a[0].compareTo(b[0]);
  sortBy(c, p) => new List.from(c)..sort(p);

  var buffer = new StringBuffer();
  sortBy(l.libraryDependencies, compareDep).forEach((dep) {
    if (dep.isImport) buffer.write('import ');
    if (dep.isExport) buffer.write('export ');
    buffer.write(n(dep.targetLibrary.simpleName));
    if (dep.isDeferred) buffer.write(' deferred');
    if (dep.prefix != null) buffer.write(' as ${n(dep.prefix)}');
    buffer.write('\n');

    List flattenedCombinators = new List();
    dep.combinators.forEach((com) {
      com.identifiers.forEach((ident) {
        flattenedCombinators.add([n(ident), com.isShow, com.isHide]);
      });
    });
    sortBy(flattenedCombinators, compareFirst).forEach((triple) {
      buffer.write(' ');
      if (triple[1]) buffer.write('show ');
      if (triple[2]) buffer.write('hide ');
      buffer.write(triple[0]);
      buffer.write('\n');
    });
  });
  return buffer.toString();
}

String stringify(value) {
  if (value == null) return '<null>';
  if (value is Map) return stringifyMap(value);
  if (value is Iterable) return stringifyIterable(value);
  if (value is InstanceMirror) return stringifyInstance(value);
  if (value is ParameterMirror) return stringifyParameter(value);
  if (value is VariableMirror) return stringifyVariable(value);
  if (value is MethodMirror) return stringifyMethod(value);
  if (value is num) return value.toString();
  if (value is String) return value;
  if (value is Symbol) return stringifySymbol(value);
  if (value is ClassMirror) return stringifyClass(value);
  if (value is TypeVariableMirror) return stringifyTypeVariable(value);
  if (value is TypeMirror) return stringifyType(value);
  throw 'Unexpected value: $value';
}

void expect(expected, actual, [String reason = ""]) {
  Expect.stringEquals(expected, stringify(actual), reason);
}

int compareSymbols(Symbol a, Symbol b) {
  return MirrorSystem.getName(a).compareTo(MirrorSystem.getName(b));
}

Iterable<Symbol> simpleNames(Iterable<Mirror> i) =>
    i.map((e) => (e as DeclarationMirror).simpleName);

List<Symbol> sort(Iterable<Symbol> symbols) =>
    symbols.toList()..sort(compareSymbols);
