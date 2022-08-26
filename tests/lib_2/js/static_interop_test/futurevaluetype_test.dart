// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `FunctionNode`'s `futureValueType`s are correctly transformed.
// See https://github.com/dart-lang/sdk/issues/48835 for more details.

@JS()
library futurevaluetype_test;

import 'dart:html';

import 'package:js/js.dart';

@JS()
@staticInterop
class JSWindow {}

// `futureValueType` corresponds to the `JSWindow` type parameter in the return
// value here. If this isn't correctly erased, we should see a runtime type
// error when using this method, as we'll be attemting to return a `@Native`
// type (`Window`) where a `package:js` type is expected instead of a
// `JavaScriptObject`.
Future<JSWindow> returnInteropType() async {
  return window as JSWindow;
}

void main() async {
  await returnInteropType();
}
