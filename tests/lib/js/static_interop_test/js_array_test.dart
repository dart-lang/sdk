// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that JS' Array type is interoperable using static interop.

@JS()
library js_array_test;

import 'dart:js_interop';

@JS()
external dynamic eval(String code);

// dart:js_interop top-levels do return-type checks so if the call to these
// getters succeed, it's enough to know they can be interoperable.

@JS()
external JSObject get jsArray;

void main() {
  eval('''
    this.jsArray = Array();
  ''');
  jsArray;
}
