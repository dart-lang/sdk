// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Test that JS-interop works without a @JS annotation on the library itself.

import 'package:js/js.dart';
import 'package:expect/expect.dart';

@JS()
external dynamic eval(String code);

void main() {
  Expect.equals(2, eval("2"));
}
