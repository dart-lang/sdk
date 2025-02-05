// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

main() async {
  int i = 1;
  Future<int> fi = Future<int>.value(i);
  Future<Future<int>> ffi = Future<Future<int>>.value(fi);
  Future<Future<Future<int>>> fffi = Future<Future<Future<int>>>.value(ffi);

  String v1 = await i;
  //          ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'String'.

  String v2 = await fi;
  //          ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'String'.

  int v3 = await ffi;
  //       ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Future<int>' can't be assigned to a variable of type 'int'.

  Future<int> v4 = await fffi;
  //               ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Future<Future<int>>' can't be assigned to a variable of type 'Future<int>'.

  Future<int> v5 = await i;
  //               ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'Future<int>'.

  Future<int> v6 = await fi;
  //               ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'Future<int>'.

  Future<FutureOr<int>> v7 = await fi;
  //                         ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'Future<FutureOr<int>>'.

  Future<Future<int>> v8 = await ffi;
  //                       ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Future<int>' can't be assigned to a variable of type 'Future<Future<int>>'.
}
