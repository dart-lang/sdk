// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is an error for a named parameter to be both `required` and have a
// default value.

class C1({required var int x = 0});
//                         ^
// [analyzer] COMPILE_TIME_ERROR.DEFAULT_VALUE_ON_REQUIRED_PARAMETER
// [cfe] Named parameter 'x' is required and can't have a default value.

class C2({required final int x = 0});
//                           ^
// [analyzer] COMPILE_TIME_ERROR.DEFAULT_VALUE_ON_REQUIRED_PARAMETER
// [cfe] Named parameter 'x' is required and can't have a default value.

class C3({required int x = 0});
//                     ^
// [analyzer] COMPILE_TIME_ERROR.DEFAULT_VALUE_ON_REQUIRED_PARAMETER
// [cfe] Named parameter 'x' is required and can't have a default value.
