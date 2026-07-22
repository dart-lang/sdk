// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  void v = 42;

  <void>[v];
  <void>[?v];
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  <void>{v};
  <void>{?v};
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  <void, void>{v: v};
  <void, void>{v: ?v};
  //               ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
  <void, void>{?v: v};
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //               ^
  // [cfe] This expression has type 'void' and can't be used.

  var v1 = [v];
  var v2 = [?v];
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  var v3 = {v};
  var v4 = {?v};
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  var v5 = {v: v};
  //        ^
  // [cfe] This expression has type 'void' and can't be used.
  //           ^
  // [cfe] This expression has type 'void' and can't be used.
  var v6 = {v: ?v};
  //        ^
  // [cfe] This expression has type 'void' and can't be used.
  //            ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
  var v7 = {?v: v};
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
  //            ^
  // [cfe] This expression has type 'void' and can't be used.

  List<void> w1 = [v];
  List<void> w2 = [?v];
  //                ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  Set<void> w3 = {v};
  Set<void> w4 = {?v};
  //               ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  Map<void, void> w5 = {v: v};
  Map<void, void> w6 = {v: ?v};
  //                        ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  // [cfe] This expression has type 'void' and can't be used.
  Map<void, void> w7 = {?v: v};
  //                     ^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //                        ^
  // [cfe] This expression has type 'void' and can't be used.
}
