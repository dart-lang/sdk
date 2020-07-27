// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that downcasting elements in collection-await-for is a compile error.
Stream<int> stream(List<int> values) => Stream.fromIterable(values);
Stream<num> numStream(List<num> values) => Stream.fromIterable(values);

void main() async {
  await testList();
  await testMap();
  await testSet();
}

Future<void> testList() async {
  // Downcast stream.
  Object obj = stream([1, 2, 3, 4]);
  var a = <int>[await for (var n in obj) n];
  //                                ^^^
  // [analyzer] COMPILE_TIME_ERROR.FOR_IN_OF_INVALID_TYPE
  // [cfe] The type 'Object' used in the 'for' loop must implement 'Stream<dynamic>'.

  // Downcast variable.
  var b = <int>[
    await for (int n in numStream([1, 2, 3, 4])) n
    //             ^
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
    //                  ^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.FOR_IN_OF_INVALID_ELEMENT_TYPE
  ];

  // Downcast element.
  var c = <int>[
    await for (num n in numStream([1, 2, 3, 4])) n
    //                                           ^
    // [analyzer] COMPILE_TIME_ERROR.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
  ];
}

Future<void> testMap() async {
  // Downcast stream.
  Object obj = stream([1, 2, 3, 4]);
  var a = <int, int>{await for (var n in obj) n: n};
  //                                     ^^^
  // [analyzer] COMPILE_TIME_ERROR.FOR_IN_OF_INVALID_TYPE
  // [cfe] The type 'Object' used in the 'for' loop must implement 'Stream<dynamic>'.

  // Downcast variable.
  var b = <int, int>{
    await for (int n in numStream([1, 2, 3, 4])) n: n
    //             ^
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
    //                  ^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.FOR_IN_OF_INVALID_ELEMENT_TYPE
  };

  // Downcast element.
  var c = <int, int>{
    await for (num n in numStream([1, 2, 3, 4])) n: n
    //                                           ^
    // [analyzer] COMPILE_TIME_ERROR.MAP_KEY_TYPE_NOT_ASSIGNABLE
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
    //                                              ^
    // [analyzer] COMPILE_TIME_ERROR.MAP_VALUE_TYPE_NOT_ASSIGNABLE
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
  };
}

Future<void> testSet() async {
  // Downcast stream.
  Object obj = stream([1, 2, 3, 4]);
  var a = <int>{await for (var n in obj) n};
  //                                ^^^
  // [analyzer] COMPILE_TIME_ERROR.FOR_IN_OF_INVALID_TYPE
  // [cfe] The type 'Object' used in the 'for' loop must implement 'Stream<dynamic>'.

  // Downcast variable.
  var b = <int>{
    await for (int n in numStream([1, 2, 3, 4])) n
    //             ^
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
    //                  ^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.FOR_IN_OF_INVALID_ELEMENT_TYPE
  };

  // Downcast element.
  var c = <int>{
    await for (num n in numStream([1, 2, 3, 4])) n
    //                                           ^
    // [analyzer] COMPILE_TIME_ERROR.SET_ELEMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
  };
}
