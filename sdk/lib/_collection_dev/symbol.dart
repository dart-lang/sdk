// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._collection.dev;

/**
 * Implementation of [core.Symbol].  This class uses the same name as
 * a core class so a user can't tell the difference.
 *
 * The purpose of this class is to hide [_name] from user code, but
 * make it accessible to Dart platform code via the static method
 * [getName].
 */
class Symbol implements core.Symbol {
  final String _name;

  external const Symbol(String name);

  /**
   * Platform-private method used by the mirror system to create
   * otherwise invalid names.
   */
  const Symbol.unvalidated(this._name);

  bool operator ==(other) => other is Symbol && _name == other._name;

  int get hashCode {
    const arbitraryPrime = 664597;
    return 0x1fffffff & (arbitraryPrime * _name.hashCode);
  }

  /// Platform-private accessor which cannot be called from user libraries.
  static String getName(Symbol symbol) => symbol._name;
}
