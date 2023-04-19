// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Test has been modified and doesn't test http://dartbug.com/275272 anymore.
// Static unresolved calls are not allowed anymore.

import "package:expect/expect.dart";

import 'dart:collection' as col;

main() {
  col.foobar(1234567);
  //  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_FUNCTION
  // [cfe] Method not found: 'foobar'.
}
