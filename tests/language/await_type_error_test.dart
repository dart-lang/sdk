// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

main() async {
  int i = 1;
  Future<int> fi = Future<int>.value(i);
  Future<Future<int>> ffi = Future<Future<int>>.value(fi);
  Future<Future<Future<int>>> fffi = Future<Future<Future<int>>>.value(ffi);

  String v1 = await i;
  //                ^
  // [analyzer] unspecified
  // [cfe] unspecified

  String v2 = await fi;
  //                ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  int v3 = await ffi;
  //             ^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Future<int> v4 = await fffi;
  //                     ^^^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Future<int> v5 = await i;
  //                     ^
  // [analyzer] unspecified
  // [cfe] unspecified

  Future<int> v6 = await fi;
  //                     ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Future<FutureOr<int>> v7 = await fi;
  //                               ^^
  // [analyzer] unspecified
  // [cfe] unspecified

  Future<Future<int>> v8 = await ffi;
  //                             ^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}
