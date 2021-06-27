// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Legacy compound literal syntax that should go away.

main() {
  var map = new Map<int>{ "a": 1, "b": 2, "c": 3 };
  //        ^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.LITERAL_WITH_CLASS_AND_NEW
  // [cfe] A map literal can't be prefixed by 'new Map'.
  //                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_ENTRY_NOT_IN_MAP
  //                         ^
  // [cfe] Expected ',' before this.
  //                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_ENTRY_NOT_IN_MAP
  //                                 ^
  // [cfe] Expected ',' before this.
  //                                      ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MAP_ENTRY_NOT_IN_MAP
  //                                         ^
  // [cfe] Expected ',' before this.
}
