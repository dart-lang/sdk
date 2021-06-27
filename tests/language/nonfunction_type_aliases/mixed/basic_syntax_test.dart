// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart = 2.9
// Requirements=nnbd-weak


// Test that the syntax associated with the non-function type aliases
// feature is supported.

import 'basic_syntax_lib.dart';

void main() {
  // Ensure that the declarations aren't eliminated by tree shaking.
  [T0, T1, T2, T3, T4, T5, T6, T7].isNotEmpty;
}
