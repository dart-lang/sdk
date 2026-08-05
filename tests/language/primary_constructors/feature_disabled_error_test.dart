// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Primary constructors are not enabled in versions before release.

// @dart=3.12

class Point(var int x, var int y);
//         ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'primary-constructors' language feature is disabled for this library.
//          ^^^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'primary-constructors' language feature is disabled for this library.
//                     ^^^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'primary-constructors' language feature is disabled for this library.
//                               ^
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'primary-constructors' language feature is disabled for this library.
