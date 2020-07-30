// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:expect/expect.dart' as prefix; // Define 'prefix'.

checkIsUnresolved(var v) {
  v is Unresolved;
  //   ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_UNDEFINED_NAME
  // [cfe] 'Unresolved' isn't a type.
  v is Unresolved<int>;
  //   ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_UNDEFINED_NAME
  // [cfe] 'Unresolved' isn't a type.
  v is prefix.Unresolved;
  //   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_UNDEFINED_NAME
  //          ^
  // [cfe] 'Unresolved' isn't a type.
  v is prefix.Unresolved<int>;
  //   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_UNDEFINED_NAME
  //          ^
  // [cfe] 'Unresolved' isn't a type.
}

checkIsListUnresolved(var v) {
  v is List<Unresolved>;
  //        ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
  // [cfe] 'Unresolved' isn't a type.
  v is List<Unresolved<int>>;
  //        ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
  // [cfe] 'Unresolved' isn't a type.
  v is List<prefix.Unresolved>;
  //        ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
  //               ^
  // [cfe] 'Unresolved' isn't a type.
  v is List<prefix.Unresolved<int>>;
  //        ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
  //               ^
  // [cfe] 'Unresolved' isn't a type.
  v is List<int, String>;
  //   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
  // [cfe] Expected 1 type arguments.
}

checkAsUnresolved(var v) {
  v as Unresolved;
  //   ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CAST_TO_NON_TYPE
  // [cfe] 'Unresolved' isn't a type.
  v as Unresolved<int>;
  //   ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CAST_TO_NON_TYPE
  // [cfe] 'Unresolved' isn't a type.
  v as prefix.Unresolved;
  //   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CAST_TO_NON_TYPE
  //          ^
  // [cfe] 'Unresolved' isn't a type.
  v as prefix.Unresolved<int>;
  //   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CAST_TO_NON_TYPE
  //          ^
  // [cfe] 'Unresolved' isn't a type.
}

checkAsListUnresolved(var v) {
  v as List<Unresolved>;
  //        ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
  // [cfe] 'Unresolved' isn't a type.
  v as List<Unresolved<int>>;
  //        ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
  // [cfe] 'Unresolved' isn't a type.
  v as List<prefix.Unresolved>;
  //        ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
  //               ^
  // [cfe] 'Unresolved' isn't a type.
  v as List<prefix.Unresolved<int>>;
  //        ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
  //               ^
  // [cfe] 'Unresolved' isn't a type.
  v as List<int, String>;
  //   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
  // [cfe] Expected 1 type arguments.
}

void main() {
  checkIsUnresolved('');
  checkAsUnresolved('');
  checkIsListUnresolved(new List());
  checkAsListUnresolved(new List());

  new undeclared_prefix.Unresolved();
  //  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'undeclared_prefix.Unresolved'.
  new undeclared_prefix.Unresolved<int>();
  //  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'undeclared_prefix.Unresolved'.

  try {
    throw 'foo';
  }
    on Unresolved
    // ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_IN_CATCH_CLAUSE
    // [cfe] 'Unresolved' isn't a type.
    catch (e) {
  }

  try {
    throw 'foo';
  }
    on Unresolved<int>
    // ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_IN_CATCH_CLAUSE
    // [cfe] 'Unresolved' isn't a type.
    catch (e) {
  }

  try {
    throw 'foo';
  }
    on prefix.Unresolved
    // ^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_IN_CATCH_CLAUSE
    //        ^
    // [cfe] 'Unresolved' isn't a type.
    catch (e) {
  }

  try {
    throw 'foo';
  }
    on prefix.Unresolved<int>
    // ^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_IN_CATCH_CLAUSE
    //        ^
    // [cfe] 'Unresolved' isn't a type.
    catch (e) {
  }

  try {
    throw 'foo';
  }
    on undeclared_prefix.Unresolved<int>
    // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_TYPE_IN_CATCH_CLAUSE
    // [cfe] 'undeclared_prefix.Unresolved' can't be used as a type because 'undeclared_prefix' isn't defined.
    catch (e) {
  }
}
