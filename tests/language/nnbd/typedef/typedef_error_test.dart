// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

/// Test that typedefs imported from opted out libraries are treated as
/// non-nullable at the top level, with legacy components.

import 'typedef_opted_out.dart';

int? takesNonNullable(int x) {}
void main() {
  F f = null; // typedefs from opted out libraries are treated as non-nullable
  //    ^^^^
  // [analyzer] STATIC_TYPE_WARNING.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Null' can't be assigned to a variable of type 'int Function(int)'.

  f = takesNonNullable; // F is int* Function(int*)
  f(null); // F is int* Function(int*)
}
