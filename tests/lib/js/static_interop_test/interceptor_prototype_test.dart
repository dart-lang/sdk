// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:expect/expect.dart';

/// Regression test for https://github.com/dart-lang/sdk/issues/56322.

/// The value returned from `Object.getPrototypeOf()` for these types
/// (for example) should be typed as a JavaScript Object.

@JS('Object.getPrototypeOf')
external JSAny? getPrototypeOf(JSAny obj);

void main() {
  Expect.type<JSObject>(getPrototypeOf(42.toJS));
  Expect.type<JSObject>(getPrototypeOf(3.14.toJS));
  Expect.type<JSObject>(getPrototypeOf('Fosse'.toJS));
  Expect.type<JSObject>(getPrototypeOf(true.toJS));
  Expect.type<JSObject>(getPrototypeOf([1.toJS, 2.toJS, 3.toJS].toJS));
}
