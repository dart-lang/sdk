// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:nonexisting/nonexisting.dart";
//     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.URI_DOES_NOT_EXIST
// [cfe] Not found: 'dart:nonexisting/nonexisting.dart'

main() {}
