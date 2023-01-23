// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// SharedOptions=--enable-experiment=records

main() {
  var record1 = (1, 2, a: 3, b: 4);
  //            ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.
  print(record1);

  // With ending comma.
  var record2 = (42, 42, 42, );
  //            ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.
  print(record2);
  var record3 = (foo: 42, bar: 42, 42, baz: 42, );
  //            ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.
  print(record3);

  // Nested.
  var record4 = ((42, 42), 42);
  //            ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.
  //             ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.
  print(record4);

  // With function inside.
  var record5 = ((foo, bar) => 42, 42);
  //            ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.
  print(record5);

  // 1 record entry with trailing comma.
  var record6 = (42, );
  //            ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.
  print(record6);

  // Const records.
  var record7 = const (42, );
  //                  ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.
  print(record7);
  var record8 = const (42, foo: "bar");
  //                  ^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'records' language feature is disabled for this library.
  print(record8);
}
