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
  const Symbol(String name)
      : this._name = name;

  @patch
  int get hashCode {
    int hash = JS('int|Null', '#._hashCode', this);
    if (hash != null) return hash;
    const arbitraryPrime = 664597;
    hash = 0x1fffffff & (arbitraryPrime * _name.hashCode);
    JS('', '#._hashCode = #', this, hash);
    return hash;
  }
}

@patch
void printToConsole(String line) {
  printString('$line');
}

@patch
List makeListFixedLength(List growableList) {
  return JSArray.markFixedList(growableList);
}

@patch
List makeFixedListUnmodifiable(List fixedLengthList) {
  return JSArray.markUnmodifiableList(fixedLengthList);
}
