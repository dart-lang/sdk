// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch library for dart:mirrors.

import 'dart:_js_helper' show patch;
import 'dart:_js_mirrors' as js;

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
    throw new ArgumentError('$key does not denote a class');
  }
  TypeMirror tm = reflectType(key);
  if (tm is! ClassMirror) {
    throw new ArgumentError("$key does not denote a class");
  }
  return (tm as ClassMirror).originalDeclaration;
}

@patch
TypeMirror reflectType(Type key, [List<Type> typeArguments]) {
  if (key == dynamic) {
    return currentMirrorSystem().dynamicType;
  }
  return js.reflectType(key, typeArguments);
}
