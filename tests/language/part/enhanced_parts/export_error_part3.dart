// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'export_error_test.dart';

// All conflict with part2 exports.
export "src/lib_decl.dart" show fx, lx, sx, Cx, Mx, Xx
// [error column 1]
// [analyzer] unspecified
// [cfe] unspecified
// [analyzer] unspecified
// [cfe] unspecified
// [analyzer] unspecified
// [cfe] unspecified
// [analyzer] unspecified
// [cfe] unspecified
// [analyzer] unspecified
// [cfe] unspecified
// [analyzer] unspecified
// [cfe] unspecified
;

// Conflicts with exported name from part 2.
var cx = 0;
//  ^
// [analyzer] unspecified
// [cfe] unspecified
