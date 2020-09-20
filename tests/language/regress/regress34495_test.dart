// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final foo = A<B>.foo();
//          ^
// [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
// [cfe] Method not found: 'A'.
//            ^
// [analyzer] COMPILE_TIME_ERROR.NON_TYPE_AS_TYPE_ARGUMENT
// [cfe] 'B' isn't a type.

main() {}
