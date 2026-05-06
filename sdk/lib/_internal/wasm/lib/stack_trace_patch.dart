// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_js_helper' show JavaScriptStack;

@patch
class StackTrace {
  @patch
  @pragma("wasm:entry-point")
  @pragma('wasm:never-inline')
  static StackTrace get current => JavaScriptStack.current();
}
