// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that `JSObject` can be used to type JS objects.

@JS()
library jsobject_type_test;

import 'dart:js_interop';

import 'package:expect/minitest.dart';

@JS()
external dynamic eval(String code);

@JS()
external Object get obj;

void main() {
  eval('''
    globalThis.obj = {};
  ''');
  expect(obj is JSObject, true);
  obj as JSObject;
}
