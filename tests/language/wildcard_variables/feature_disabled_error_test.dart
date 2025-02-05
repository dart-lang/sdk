// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Wildcard variables are not enabled in versions earlier than 3.7.

// @dart=3.6

main() {
  int _ = 1;
  var _ = 2;
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] '_' is already declared in this scope.
}
