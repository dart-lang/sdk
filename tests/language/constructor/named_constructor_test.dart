// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library named_constructor_test;

import 'package:expect/expect.dart';
import 'named_lib.dart' as prefix;

class Class<T> {
  final int value;
  Class() : value = 0;
  Class.named() : value = 1;
}

void main() {
  Expect.equals(0, new Class().value);
  Expect.equals(0, new Class<int>().value);

  Expect.equals(1, new Class.named().value);
  Expect.equals(1, new Class<int>.named().value);
  // 'Class.named' is not a type:
  new Class.named<int>().value;
  //        ^
  // [cfe] A constructor invocation can't have type arguments on the constructor name.
  //             ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR

  // 'Class<int>.named<int>' doesn't fit the grammar syntax T.id:
  new Class<int>.named<int>().value;
  //             ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR
  // [cfe] A constructor invocation can't have type arguments on the constructor name.

  new prefix.Class().value;
  // 'prefix' is not a type:
  new prefix<int>.Class().value;
  //  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'prefix.Class'.
  new prefix.Class<int>().value;
  // 'prefix<int>.Class<int>' doesn't fit the grammar syntax T.id:
  new prefix<int>.Class<int>().value;
  //  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'prefix.Class'.
  //              ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR
  // [cfe] A constructor invocation can't have type arguments on the constructor name.

  new prefix.Class.named().value;
  // 'prefix<int>.Class.named' doesn't fit the grammar syntax T.id:
  new prefix<int>.Class.named().value;
  //  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'prefix.Class'.
  //              ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected '(' after this.


  // 'prefix.Class<int>.named' doesn't fit the grammar syntax T.id:
  new prefix.Class<int>.named().value;
  // 'prefix.Class.named<int>' doesn't fit the grammar syntax T.id:
  new prefix.Class.named<int>().value;
  //               ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR
  // [cfe] A constructor invocation can't have type arguments on the constructor name.

  // 'prefix<int>.Class<int>' doesn't fit the grammar syntax T.id:
  new prefix<int>.Class<int>.named().value;
  //  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'prefix.Class'.
  //              ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR
  // [cfe] A constructor invocation can't have type arguments on the constructor name.


  // 'prefix<int>.Class.named<int>' doesn't fit the grammar syntax T.id:
  new prefix<int>.Class.named<int>().value;
  //  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'prefix.Class'.
  //              ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected '(' after this.


  // 'prefix.Class<int>.named<int>' doesn't fit the grammar syntax T.id:
  new prefix.Class<int>.named<int>().value;
  //                    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR
  // [cfe] A constructor invocation can't have type arguments on the constructor name.

  // 'prefix<int>.Class<int>.named<int>' doesn't fit the grammar syntax T.id:
  new prefix<int>.Class<int>.named<int>().value;
  //  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'prefix.Class'.
  //              ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR
  // [cfe] A constructor invocation can't have type arguments on the constructor name.
}
