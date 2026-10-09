// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper" show JS, jsStringFromDartString, JSExternWrapperExt;
import "dart:_wasm";

@patch
void printToConsole(String line) => JS<WasmVoid>(
  's => printToConsole(s)',
  jsStringFromDartString(line).wrappedExternRef,
);
