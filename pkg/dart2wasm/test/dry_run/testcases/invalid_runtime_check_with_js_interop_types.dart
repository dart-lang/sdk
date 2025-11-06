// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

extension type Window._(JSObject _) implements JSObject {}

void main() {
  int dartInt = 0;
  // DRY_RUN: 6, Cast from 'int' to 'JSObject' casts a Dart value to a JS
  // interop type
  dartInt as JSObject;
  // DRY_RUN: 7, Runtime check between 'int' and 'JSBoolean' checks whether a
  // Dart value is a JS interop type
  dartInt is JSBoolean;
  JSNumber jsNum = dartInt.toJS;
  // DRY_RUN: 8, Cast from 'JSNumber' to 'String' casts a JS interop value to a
  // Dart type
  jsNum as String;
  // DRY_RUN: 9, Runtime check between 'JSNumber' and 'int' checks whether a JS
  // interop value is a Dart type
  jsNum is int;
  // DRY_RUN: 10, Cast from 'JSNumber' to 'JSTypedArray' casts a JS interop
  // value to an incompatible JS interop type
  jsNum as JSTypedArray;
  // DRY_RUN: 11, Runtime check between 'JSNumber' and 'JSBigInt' involves a
  // non-trivial runtime check between two JS interop types
  jsNum is JSBigInt;
  // DRY_RUN: 12, Runtime check between 'JSObject' and 'Window' involves a
  // runtime check between a JS interop value and an unrelated JS interop type
  JSObject() is Window;
  // Users are allowed to ignore lints still.
  // ignore: invalid_runtime_check_with_js_interop_types
  dartInt as JSString;
}
