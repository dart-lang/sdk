// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-mirrors=false

// Verifies that '--enable-mirrors=false' affects conditional imports and
// constant bool.fromEnvironment.

import "package:expect/expect.dart";

import 'enable_mirrors_lib_false.dart'
    if (dart.library.mirrors) 'enable_mirrors_lib_true.dart';

main() {
  Expect.isFalse(const bool.fromEnvironment('dart.library.mirrors'));
  Expect.isFalse(dartLibraryMirrorsConditionalImport);
}
