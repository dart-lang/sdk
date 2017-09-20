// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a private library cannot be accessed from outside the platform.

library internal_library_test;

import 'dart:core'; // This loads 'dart:_foreign_helper' and 'patch:core'.
import 'dart:_foreign_helper'; //# 01: compile-time error

part 'dart:_foreign_helper'; //# 02: compile-time error

void main() {
  JS('int', '0'); //# 01: continued
  JS('int', '0'); //# 02: continued
}
