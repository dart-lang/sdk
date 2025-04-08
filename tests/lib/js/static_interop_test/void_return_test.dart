// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that `void` return values can be passed around as Dart objects.

import 'dart:js_interop';

@JS()
external void eval(String code);

void main() {
  Object? x = eval('1 + 1') as dynamic;

  // It doesn't matter what this prints, it just shouldn't crash.
  print(x);
}
