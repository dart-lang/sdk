// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that JS error types are interoperable.

@JS()
library native_error_test;

import 'dart:js_interop';

@JS()
external dynamic eval(String code);

// dart:js_interop top-levels do return-type checks so if the call to these
// getters succeed, it's enough to know they can be interoperable.

@JS()
external JSObject get error;

@JS()
external JSObject get rangeError;

void main() {
  eval('''
    this.error = Error();
    this.rangeError = RangeError();
  ''');
  error;
  rangeError;
}
