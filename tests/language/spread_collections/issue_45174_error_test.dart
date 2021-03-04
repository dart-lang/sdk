// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

f(Object? objectQuestion) {
  return {...<int>{}, ...objectQuestion};
  //     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER
  //                     ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  //                     ^
  // [cfe] Unexpected type 'Object?' of a map spread entry.  Expected 'dynamic' or a Map.
}

main() {}
