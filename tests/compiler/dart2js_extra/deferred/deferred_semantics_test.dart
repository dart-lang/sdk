// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that deferred loading requires same library names.

import 'dart:async';

@lazy  /// 01: compile-time error
import 'deferred_function_library.dart';

const lazy = const DeferredLibrary('fisk');

main() {
}
