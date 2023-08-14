// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Test that an unresolved identifier at the top level causes a compile-time
// error.

var a = b;
//      ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] Undefined name 'b'.

main() {
  print(a);
}
