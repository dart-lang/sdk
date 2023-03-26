// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// SharedOptions=--enable-experiment=records

main() {
  (int, int, {/*missing*/}) r1 = (1, 2);
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                       ^
// [analyzer] SYNTACTIC_ERROR.EMPTY_RECORD_TYPE_NAMED_FIELDS_LIST
// [cfe] The list of named fields in a record type can't be empty.
//                               ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.

  (int /* missing trailing comma */ ) r2 = (1, );
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                                  ^
// [analyzer] SYNTACTIC_ERROR.RECORD_TYPE_ONE_POSITIONAL_NO_TRAILING_COMMA
// [cfe] A record type with exactly one positional field requires a trailing comma.
//                                         ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.

  () emptyRecord = ();
//^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] This requires the experimental 'records' language feature to be enabled.
//                 ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'records' language feature is disabled for this library.
  print(emptyRecord);
}
