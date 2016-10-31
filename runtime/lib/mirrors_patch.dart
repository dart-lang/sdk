// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async" show Future;
import "dart:collection" show UnmodifiableListView, UnmodifiableMapView;
import "dart:_internal" as internal;

/**
 * Returns a [MirrorSystem] for the current isolate.
 */
@patch MirrorSystem currentMirrorSystem() {
  return _Mirrors.currentMirrorSystem();
}

/**
 * Returns an [InstanceMirror] for some Dart language object.
 *
 * This only works if this mirror system is associated with the
 * current running isolate.
 */
@patch InstanceMirror reflect(Object reflectee) {
  return _Mirrors.reflect(reflectee);
}

/**
 * Returns a [ClassMirror] for the class represented by a Dart
 * Type object.
 *
 * This only works with objects local to the current isolate.
 */
@patch ClassMirror reflectClass(Type key) {
  return _Mirrors.reflectClass(key);
}

@patch TypeMirror reflectType(Type key) {
  return _Mirrors.reflectType(key);
}

@patch class MirrorSystem {
  @patch LibraryMirror findLibrary(Symbol libraryName) {
    var candidates =
        libraries.values.where((lib) => lib.simpleName == libraryName);
    if (candidates.length == 1) {
      return candidates.single;
    }
    if (candidates.length > 1) {
      var uris = candidates.map((lib) => lib.uri.toString()).toList();
      throw new Exception("There are multiple libraries named "
                          "'${getName(libraryName)}': $uris");
    }
    throw new Exception("There is no library named '${getName(libraryName)}'");
  }

  @patch static String getName(Symbol symbol) {
    return internal.Symbol.getUnmangledName(symbol);
  }

  @patch static Symbol getSymbol(String name, [LibraryMirror library]) {
    if ((library != null && library is! _LocalLibraryMirror) ||
        ((name.length > 0) && (name[0] == '_') && (library == null))) {
      throw new ArgumentError(library);
    }
    if (library != null) name = _mangleName(name, library._reflectee);
    return new internal.Symbol.unvalidated(name);
  }

  static _mangleName(String name, _MirrorReference lib)
      native "Mirrors_mangleName";
}
