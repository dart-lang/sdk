// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that tearoffs of `loadLibrary` work properly.
//
// The CFE chooses a non identifier name for `loadLibrary` methods, this test
// ensures that not only we properly escape the name of the method but also the
// name of the derived tearoff closure.
import "deferred_tearoff_load_library_lib.dart" deferred as lib;

import "package:async_helper/async_helper.dart";

@pragma('dart2js:noInline')
get tearoff => lib.loadLibrary;

main() {
  asyncStart();
  tearoff().then((_) => asyncEnd());
}
