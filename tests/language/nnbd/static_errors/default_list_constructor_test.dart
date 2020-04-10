// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that it is an error to call the default List constructor.
main() {
  var a = new List<int>(3);
  //          ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DEFAULT_LIST_CONSTRUCTOR
  // [cfe] Can't use the default List constructor.
  var b = new List<int?>(3);
  //          ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DEFAULT_LIST_CONSTRUCTOR
  // [cfe] Can't use the default List constructor.
  var c = new List<int>();
  //          ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DEFAULT_LIST_CONSTRUCTOR
  // [cfe] Can't use the default List constructor.
  var d = new List<int?>();
  //          ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DEFAULT_LIST_CONSTRUCTOR
  // [cfe] Can't use the default List constructor.
  List<C> e = new List(5);
  //              ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DEFAULT_LIST_CONSTRUCTOR
  // [cfe] Can't use the default List constructor.
}

class A<T> {
  var l = new List<T>(3);
  //          ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DEFAULT_LIST_CONSTRUCTOR
  // [cfe] Can't use the default List constructor.
}

class C {}
