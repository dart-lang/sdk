// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_js_primitives' show printString;
import 'dart:_js_helper' show JS, patch;
import 'dart:_interceptors' show JSArray;

@patch
class Symbol implements core.Symbol {
  @patch
  const Symbol(String name)
      : this._name = name;
}

@patch
void printToConsole(String line) {
  printString('$line');
}

@patch
List makeListFixedLength(List growableList) {
  JSArray.markFixedList(growableList);
  return growableList;
}
