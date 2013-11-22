// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_js_primitives' show printString;

patch class Symbol implements core.Symbol {
  patch const Symbol(String name)
      : this._name = name;
}

patch void printToConsole(String line) {
  printString('$line');
}
