// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// SharedOptions=--enable-experiment=records

main() {
  (int, int) record1 = (1, 2);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                     ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.
  print(record1);
  (int x, int y) record1Named = (1, 2);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                              ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.
  print(record1Named);

  (int, int, ) record2 = (1, 2);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                       ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.
  print(record2);

  (int x, int y, ) record2Named = (1, 2);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                                ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.
  print(record2Named);

  (int, int, {int a, int b}) record3 = (1, 2, a: 3, b: 4);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                                     ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.
  print(record3);

  (int x, int y, {int a, int b}) record3Named = (1, 2, a: 3, b: 4);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                                              ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.
  print(record3Named);

  (int, int, {int a, int b, }) record4 = (1, 2, a: 3, b: 4);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                                       ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.
  print(record4);

  (int x, int y, {int a, int b, }) record4Named = (1, 2, a: 3, b: 4);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                                                ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.
  print(record4Named);

  print(foo((42, b: true), 42));
  //        ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.

  Bar b = new Bar();
  print(b.foo(42));
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
// [cfe] The 'records' language feature is disabled for this library.

  final (int x, int y) finalRecordType = (42, 42);
  //    ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'records' language feature to be enabled.
  //                                     ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.

  List<(int, int)> listOfRecords = [];
  //   ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'records' language feature to be enabled.

  var listOfRecords2 = <(int, int)>[];
  //                    ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'records' language feature to be enabled.

  (int, ) oneElementRecord = (1, );
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                           ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.
  print(oneElementRecord);

  ({int ok}) oneElementNamedRecord = (ok: 1);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                                   ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.
  print(oneElementNamedRecord);
}

(int, T) f1<T>(T t) {
// [error column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
  return (42, t);
  //     ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.
}

(int, T) f2<T>(T t) => (42, t);
// [error column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                     ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.

(int a, String b) get topLevelGetterType => throw '';
// [error column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.

(int, int) foo((int, {bool b}) inputRecord, int x) {
// [error column 1, length 1]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//             ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
  if (inputRecord.b) return (42, 42);
  //                        ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.
  return (1, 1, );
  //     ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.
}

class Bar {
  (int, int) foo(int x) => (42, 42);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                         ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.

  static (int x, int y) staticRecordType = (42, 42);
  //     ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] This requires the experimental 'records' language feature to be enabled.
  //                                       ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.

  (int a, String b) get instanceGetterType => throw '';
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.

  static (int a, String b) get staticGetterType => throw '';
//       ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.

  (int, T) f1<T>(T t) {
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
    return (42, t);
    //     ^
    // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
    // [cfe] The 'records' language feature is disabled for this library.
  }

  (int, T) f2<T>(T t) => (42, t);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                       ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.
}

