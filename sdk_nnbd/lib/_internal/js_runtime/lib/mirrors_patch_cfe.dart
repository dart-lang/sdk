// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Patch library for dart:mirrors.

import 'dart:_js_helper' show patch;
import 'dart:mirrors';

const String _message = 'dart:mirrors is no longer supported for web apps';

@patch
MirrorSystem currentMirrorSystem() => throw new UnsupportedError(_message);

@patch
InstanceMirror reflect(dynamic reflectee) =>
    throw new UnsupportedError(_message);

@patch
ClassMirror reflectClass(Type key) => throw new UnsupportedError(_message);

@patch
TypeMirror reflectType(Type key, [List<Type> typeArguments]) =>
    throw new UnsupportedError(_message);

@patch
abstract class MirrorSystem {
  Map<Uri, LibraryMirror> get libraries;
  IsolateMirror get isolate;
  TypeMirror get dynamicType;
  TypeMirror get voidType;
  TypeMirror get neverType;

  @patch
  LibraryMirror findLibrary(Symbol libraryName) =>
      throw new UnsupportedError(_message);

  @patch
  static String getName(Symbol symbol) => throw new UnsupportedError(_message);

  @patch
  static Symbol getSymbol(String name, [LibraryMirror library]) =>
      throw new UnsupportedError(_message);
}
