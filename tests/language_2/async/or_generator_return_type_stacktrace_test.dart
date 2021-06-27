// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

int badReturnTypeAsync() async {}
// [error line 9, column 1, length 3]
// [analyzer] COMPILE_TIME_ERROR.ILLEGAL_ASYNC_RETURN_TYPE
//  ^
// [cfe] Functions marked 'async' must have a return type assignable to 'Future'.
int badReturnTypeAsyncStar() async* {}
// [error line 14, column 1, length 3]
// [analyzer] COMPILE_TIME_ERROR.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE
//  ^
// [cfe] Functions marked 'async*' must have a return type assignable to 'Stream'.
int badReturnTypeSyncStar() sync* {}
// [error line 19, column 1, length 3]
// [analyzer] COMPILE_TIME_ERROR.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE
//  ^
// [cfe] Functions marked 'sync*' must have a return type assignable to 'Iterable'.

void main() {}
