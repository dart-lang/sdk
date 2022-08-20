// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

main() {
  (int, int) record1 = (1, 2);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                     ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
  print(record1);
  //    ^
  // [cfe] This expression has type 'void' and can't be used.
  (int x, int y) record1Named = (1, 2);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                              ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
  print(record1Named);
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  (int, int, ) record2 = (1, 2);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                       ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
  print(record2);
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  (int x, int y, ) record2Named = (1, 2);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                                ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
  print(record2Named);
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  (int, int, {int a, int b}) record3 = (1, 2, a: 3, b: 4);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                                     ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
  print(record3);
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  (int x, int y, {int a, int b}) record3Named = (1, 2, a: 3, b: 4);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                                              ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
  print(record3Named);
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  (int, int, {int a, int b, }) record4 = (1, 2, a: 3, b: 4);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                                       ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
  print(record4);
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  (int x, int y, {int a, int b, }) record4Named = (1, 2, a: 3, b: 4);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                                                ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
  print(record4Named);
  //    ^
  // [cfe] This expression has type 'void' and can't be used.

  print(foo((42, b: true), 42));
  //    ^
  // [cfe] This expression has type 'void' and can't be used.
  //        ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'records' language feature to be enabled.

  Bar b = new Bar();
  print(b.foo(42));
  //      ^
  // [cfe] This expression has type 'void' and can't be used.
  (int, int) Function ((int, int) a) z1 = ((int, int) a) { return (42, 42); };
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                     ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                                         ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                                                                ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
}

(int, int) foo((int, {bool b}) inputRecord, int x) {
// [error column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//             ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
  if (inputRecord.b) return (42, 42);
  //  ^
  // [cfe] This expression has type 'void' and can't be used.
  //              ^
  // [cfe] The getter 'b' isn't defined for the class 'void'.
  //                        ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'records' language feature to be enabled.
  return (1, 1, );
  //     ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'records' language feature to be enabled.
}

class Bar {
  (int, int) foo(int x) => (42, 42);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                         ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
}

