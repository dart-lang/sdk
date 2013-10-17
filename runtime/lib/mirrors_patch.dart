// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:nativewrappers";
// TODO(ahe): Move _symbol_dev.Symbol to its own "private" library?
import "dart:_collection-dev" as _symbol_dev;

/**
 * Returns a [MirrorSystem] for the current isolate.
 */
patch MirrorSystem currentMirrorSystem() {
  return _Mirrors.currentMirrorSystem();
}

/**
 * Creates a [MirrorSystem] for the isolate which is listening on
 * the [SendPort].
 */
patch Future<MirrorSystem> mirrorSystemOf(SendPort port) {
  return _Mirrors.mirrorSystemOf(port);
}

/**
 * Returns an [InstanceMirror] for some Dart language object.
 *
 * This only works if this mirror system is associated with the
 * current running isolate.
 */
patch InstanceMirror reflect(Object reflectee) {
  return _Mirrors.reflect(reflectee);
}

/**
 * Returns a [ClassMirror] for the class represented by a Dart
 * Type object.
 *
 * This only works with objects local to the current isolate.
 */
patch ClassMirror reflectClass(Type key) {
  return _Mirrors.reflectClass(key);
}

patch class MirrorSystem {
  /* patch */ static String getName(Symbol symbol) {
    String string = _symbol_dev.Symbol.getName(symbol);
    if (string.contains(' with ')) return string;
    return _unmangleName(string);
  }
  /* patch */ static Symbol getSymbol(String name, [LibraryMirror library]) {
    if (library is! LibraryMirror ||
        ((name[0] == '_') && (library == null))) {
      throw new ArgumentError(library);
    }
    if (library != null) name = _mangleName(name, library._reflectee);
    return new _symbol_dev.Symbol.unvalidated(name);
  }

  static _unmangleName(String name)
      native "Mirrors_unmangleName";
  static _mangleName(String name, _MirrorReference lib)
      native "Mirrors_mangleName";
}
