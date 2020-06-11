// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "../library10.dart" as lib10;
//                            ^
// [cfe] 'lib10' is already declared in this scope.

// Top level variables cannot shadow library prefixes, they should collide.
var lib10;
//  ^^^^^
// [analyzer] COMPILE_TIME_ERROR.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER

main() {}
