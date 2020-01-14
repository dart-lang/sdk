// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "prefix_constraints_lib.dart" deferred as lib;
//                                   ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SHARED_DEFERRED_PREFIX
import "prefix_constraints_lib2.dart" deferred as lib;
//                                    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SHARED_DEFERRED_PREFIX
//                                                ^
// [cfe] Can't use the name 'lib' for a deferred library, as the name is used elsewhere.

void main() {}
