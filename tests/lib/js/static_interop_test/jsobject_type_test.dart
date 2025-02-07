// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that `JSObject` can be used to type JS objects.

import 'dart:js_interop';
import 'package:expect/expect.dart';

@JS()
external void eval(String code);

@JS()
external JSAny get obj;

void main() {
  eval('''
    globalThis.obj = {};
  ''');
  Expect.isTrue(obj is JSObject);
  obj as JSObject;
}
