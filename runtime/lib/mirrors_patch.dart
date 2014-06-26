// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" as _symbol_dev;

/**
 * Returns a [MirrorSystem] for the current isolate.
 */
patch MirrorSystem currentMirrorSystem() {
  return _Mirrors.currentMirrorSystem();
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

patch TypeMirror reflectType(Type key) {
  return _Mirrors.reflectType(key);
}

patch class MirrorSystem {
  /* patch */ LibraryMirror findLibrary(Symbol libraryName) {
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

  /* patch */ static String getName(Symbol symbol) {
    String string = _symbol_dev.Symbol.getName(symbol);

    // get:foo -> foo
    // set:foo -> foo=
    // get:_foo@xxx -> _foo
    // set:_foo@xxx -> _foo=
    // Class._constructor@xxx -> Class._constructor
    // _Class@xxx._constructor@xxx -> _Class._constructor
    // lib._S@xxx with lib._M1@xxx, lib._M2@xxx -> lib._S with lib._M1, lib._M2
    StringBuffer result = new StringBuffer();
    bool add_setter_suffix = false;
    var pos = 0;
    if (string.length >= 4 && string[3] == ':') {
      // Drop 'get:' or 'set:' prefix.
      pos = 4;
      if (string[0] == 's') {
        add_setter_suffix = true;
      }
    }
    // Skip everything between AT and PERIOD, SPACE, COMMA or END
    bool skip = false;
    for (; pos < string.length; pos++) {
      var char = string[pos];
      if (char == '@') {
        skip = true;
      } else if (char == '.' || char == ' ' || char == ',') {
        skip = false;
      }
      if (!skip) {
        result.write(char);
      }
    }
    if (add_setter_suffix) {
      result.write('=');
    }
    return result.toString();
  }

  /* patch */ static Symbol getSymbol(String name, [LibraryMirror library]) {
    if ((library != null && library is! _LocalLibraryMirror) ||
        ((name.length > 0) && (name[0] == '_') && (library == null))) {
      throw new ArgumentError(library);
    }
    if (library != null) name = _mangleName(name, library._reflectee);
    return new _symbol_dev.Symbol.unvalidated(name);
  }

  static _mangleName(String name, _MirrorReference lib)
      native "Mirrors_mangleName";
}

// TODO(rmacnak): Eliminate this class.
class MirroredCompilationError {
  final String message;

  MirroredCompilationError(this.message);

  String toString() {
    return "Compile-time error during mirrored execution: <$message>";
  }
}
