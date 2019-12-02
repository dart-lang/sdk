// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

// Patch library for dart:mirrors.

import 'dart:_js_helper' show patch;
import 'dart:_js_mirrors' as js;
import 'dart:_runtime' as dart;

@patch
class MirrorSystem {
  @patch
  LibraryMirror findLibrary(Symbol libraryName) {
    return libraries.values
        .singleWhere((library) => library.simpleName == libraryName);
  }

  @patch
  static String getName(Symbol symbol) => js.getName(symbol);

  @patch
  static Symbol getSymbol(String name, [LibraryMirror library]) {
    return js.getSymbol(name, library);
  }
}

@patch
MirrorSystem currentMirrorSystem() => js.currentJsMirrorSystem;

@patch
InstanceMirror reflect(Object reflectee) => js.reflect(reflectee);

@patch
ClassMirror reflectClass(Type key) {
  if (key is! Type || key == dynamic) {
    throw ArgumentError('$key does not denote a class');
  }
  TypeMirror tm = reflectType(key);
  if (tm is! ClassMirror) {
    throw ArgumentError("$key does not denote a class");
  }
  return (tm as ClassMirror).originalDeclaration;
}

@patch
TypeMirror reflectType(Type type, [List<Type> typeArguments]) {
  if (typeArguments != null) {
    type = _instantiateClass(type, typeArguments);
  }
  return js.reflectType(type);
}

/// Instantiates the generic class [type] with [typeArguments] and returns the
/// result.
///
/// [type] may be instantiated with type arguments already. In that case, they
/// are ignored. For example calling this function with `(List<int>, [String])`
/// and `(List<dynamic>, [String])` will produce `List<String>` in both cases.
Type _instantiateClass(Type type, List<Type> typeArguments) {
  var unwrapped = dart.unwrapType(type);
  var genericClass = dart.getGenericClass(unwrapped);
  if (genericClass == null) {
    throw ArgumentError('Type `$type` must be generic to apply '
        'type arguments: `$typeArguments`.');
  }

  var typeArgsLenth = typeArguments.length;
  var unwrappedArgs = List(typeArgsLenth);
  for (int i = 0; i < typeArgsLenth; i++) {
    unwrappedArgs[i] = dart.unwrapType(typeArguments[i]);
  }
  var typeFormals = dart.getGenericTypeFormals(genericClass);
  if (typeFormals.length != typeArgsLenth) {
    throw ArgumentError('Type `$type` has ${typeFormals.length} type '
        'parameters, but $typeArgsLenth type arguments were '
        'passed: `$typeArguments`.');
  }
  // TODO(jmesserly): this does not validate bounds, as we don't have them
  // available at runtime. Consider storing them when dart:mirrors is enabled.
  return dart.wrapType(dart.instantiateClass(genericClass, unwrappedArgs));
}
