// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-ffi

import 'package:expect/expect.dart';

import 'disabled_helper.dart' if (dart.library.ffi) 'enabled_helper.dart';

void main() {
  Expect.isTrue(const bool.fromEnvironment('dart.library.ffi'));
  Expect.equals('Have dart:ffi support (10)', tryAccessFfi());
}
