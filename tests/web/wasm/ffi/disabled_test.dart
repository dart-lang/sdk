// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'disabled_helper.dart' if (dart.library.ffi) 'enabled_helper.dart';

void main() {
  Expect.isFalse(const bool.fromEnvironment('dart.library.ffi'));
  Expect.equals('Have no dart:ffi support', tryAccessFfi());
}
