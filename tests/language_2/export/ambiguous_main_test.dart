// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

export 'ambiguous_main_a.dart';
export 'ambiguous_main_b.dart';
// [error column 1]
// [cfe] 'main' is exported from both 'tests/language_2/export/ambiguous_main_a.dart' and 'tests/language_2/export/ambiguous_main_b.dart'.
//     ^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.AMBIGUOUS_EXPORT
