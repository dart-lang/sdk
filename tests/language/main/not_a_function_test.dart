// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {}

var main;
//  ^^^^
// [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
// [analyzer] COMPILE_TIME_ERROR.MAIN_IS_NOT_FUNCTION
// [cfe] 'main' is already declared in this scope.
// [cfe] The 'main' declaration must be a function declaration.
