// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch  class Symbol {
  final String _name;
  /* patch */ const Symbol(String name)
    : this._name = _validate(name);


  static final RegExp _validationPattern =
      new RegExp(r'^[a-zA-Z$][a-zA-Z$0-9_]*=?');

  static _validate(String name) {
    if (name is! String) throw new ArgumentError('name must be a String');
    if (name.isEmpty) return;
    if (name.startsWith('_')) {
      throw new ArgumentError('"$name" is a private identifier');
    }
    if (!_validationPattern.hasMatch(name)) {
      throw new ArgumentError(
	  '"$name" is not an identifier or an empty String');
    }
    return name;
  }

  /* patch */ bool operator ==(other) {
    return other is Symbol && _name == other._name;
  }

  /* patch */ int get hashCode {
    const arbitraryPrime = 664597;
    return 0x1fffffff & (arbitraryPrime * _name.hashCode);
  }
}
