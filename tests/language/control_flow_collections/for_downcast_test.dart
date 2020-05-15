// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that downcasting elements in collection-for is a compile error.
void main() {
  testList();
  testMap();
  testSet();
  testNullIterable();
}

void testList() {
  // Downcast iterable.
  Object obj = <int>[1, 2, 3, 4];
  var a = <int>[for (var n in obj) n];
  //                          ^^^
  // [analyzer] STATIC_TYPE_WARNING.FOR_IN_OF_INVALID_TYPE
  // [cfe] The type 'Object' used in the 'for' loop must implement 'Iterable<dynamic>'.

  // Downcast variable.
  var b = <int>[
    for (int n in <num>[1, 2, 3, 4]) n
    //       ^
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
    //            ^^^^^^^^^^^^^^^^^
    // [analyzer] STATIC_TYPE_WARNING.FOR_IN_OF_INVALID_ELEMENT_TYPE
  ];

  // Downcast element.
  var c = <int>[
    for (num n in <num>[1, 2, 3, 4]) n
    //                               ^
    // [analyzer] STATIC_WARNING.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
  ];

  // Downcast condition.
  var d = <int>[for (var i = 1; (i < 2) as Object; i++) i];
  //                            ^^^^^^^^^^^^^^^^^
  // [analyzer] STATIC_TYPE_WARNING.NON_BOOL_CONDITION
  //                                    ^
  // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
}

void testMap() {
  // Downcast iterable.
  Object obj = <int>[1, 2, 3, 4];
  var a = <int, int>{for (var n in obj) n: n};
  //                               ^^^
  // [analyzer] STATIC_TYPE_WARNING.FOR_IN_OF_INVALID_TYPE
  // [cfe] The type 'Object' used in the 'for' loop must implement 'Iterable<dynamic>'.

  // Downcast variable.
  var b = <int, int>{
    for (int n in <num>[1, 2, 3, 4]) n: n
    //       ^
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
    //            ^^^^^^^^^^^^^^^^^
    // [analyzer] STATIC_TYPE_WARNING.FOR_IN_OF_INVALID_ELEMENT_TYPE
  };

  // Downcast element.
  var c = <int, int>{
    for (num n in <num>[1, 2, 3, 4]) n: n
    //                               ^
    // [analyzer] STATIC_WARNING.MAP_KEY_TYPE_NOT_ASSIGNABLE
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
    //                                  ^
    // [analyzer] STATIC_WARNING.MAP_VALUE_TYPE_NOT_ASSIGNABLE
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
  };

  // Downcast condition.
  var d = <int, int>{for (var i = 1; (i < 2) as Object; i++) i: i};
  //                                 ^^^^^^^^^^^^^^^^^
  // [analyzer] STATIC_TYPE_WARNING.NON_BOOL_CONDITION
  //                                         ^
  // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
}

void testSet() {
  // Downcast iterable.
  Object obj = <int>[1, 2, 3, 4];
  var a = <int>{for (var n in obj) n};
  //                          ^^^
  // [analyzer] STATIC_TYPE_WARNING.FOR_IN_OF_INVALID_TYPE
  // [cfe] The type 'Object' used in the 'for' loop must implement 'Iterable<dynamic>'.

  // Downcast variable.
  var b = <int>{
    for (int n in <num>[1, 2, 3, 4]) n
    //       ^
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
    //            ^^^^^^^^^^^^^^^^^
    // [analyzer] STATIC_TYPE_WARNING.FOR_IN_OF_INVALID_ELEMENT_TYPE
  };

  // Downcast element.
  var c = <int>{
    for (num n in <num>[1, 2, 3, 4]) n
    //                               ^
    // [analyzer] STATIC_WARNING.SET_ELEMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
  };

  // Downcast condition.
  var d = <int>{for (var i = 1; (i < 2) as Object; i++) i};
  //                            ^^^^^^^^^^^^^^^^^
  // [analyzer] STATIC_TYPE_WARNING.NON_BOOL_CONDITION
  //                                    ^
  // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
}

void testNullIterable() {
  // Null iterable.
  Iterable<int>? nullIterable = null;
  var a = <int>[for (var i in nullIterable) 1];
  //                          ^^^^^^^^^^^^
  // [analyzer] STATIC_WARNING.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] The type 'Iterable<int>?' used in the 'for' loop must implement 'Iterable<dynamic>'.
  var b = {for (var i in nullIterable) 1: 1};
  //                     ^^^^^^^^^^^^
  // [analyzer] STATIC_WARNING.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] The type 'Iterable<int>?' used in the 'for' loop must implement 'Iterable<dynamic>'.
  var c = <int>{for (var i in nullIterable) 1};
  //                          ^^^^^^^^^^^^
  // [analyzer] STATIC_WARNING.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe] The type 'Iterable<int>?' used in the 'for' loop must implement 'Iterable<dynamic>'.
}
