// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_js_primitives' show printString;
import 'dart:_js_helper' show patch;
import 'dart:_interceptors' show JSArray;
import 'dart:_foreign_helper' show JS;

@patch
class Symbol implements core.Symbol {
  @patch
  const Symbol(String name) : this._name = name;

  @patch
  int get hashCode {
    int hash = JS('int|Null', '#._hashCode', this);
    if (hash != null) return hash;
    const arbitraryPrime = 664597;
    hash = 0x1fffffff & (arbitraryPrime * _name.hashCode);
    JS('', '#._hashCode = #', this, hash);
    return hash;
  }

  @patch
  toString() => 'Symbol("$_name")';
}

/// Used internally by DDC to map ES6 symbols to Dart.
class PrivateSymbol implements core.Symbol {
  // TODO(jmesserly): could also get this off the native symbol instead of
  // storing it. Mirrors already does this conversion.
  final String _name;
  final Object _nativeSymbol;

  const PrivateSymbol(this._name, this._nativeSymbol);

  static String getName(core.Symbol symbol) => (symbol as PrivateSymbol)._name;

  static Object getNativeSymbol(core.Symbol symbol) {
    if (symbol is PrivateSymbol) return symbol._nativeSymbol;
    return null;
  }

  bool operator ==(other) =>
      other is PrivateSymbol &&
      _name == other._name &&
      identical(_nativeSymbol, other._nativeSymbol);

  get hashCode => _name.hashCode;

  // TODO(jmesserly): is this equivalent to _nativeSymbol toString?
  toString() => 'Symbol("$_name")';
}

@patch
void printToConsole(String line) {
  printString('$line');
}

@patch
List/*<E>*/ makeListFixedLength/*<E>*/(List/*<E>*/ growableList) {
  JSArray.markFixedList(growableList);
  return growableList;
}

@patch
List/*<E>*/ makeFixedListUnmodifiable/*<E>*/(List/*<E>*/ fixedLengthList) {
  JSArray.markUnmodifiableList(fixedLengthList);
  return fixedLengthList;
}
