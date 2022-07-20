// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=-Ddart2js=true

// Behavioral test for annotations that control checking of late fields.
// See `late_field_checks_common.dart` for details.

import 'package:expect/expect.dart';

import 'late_field_checks_common.dart' show libraryName;
import 'late_field_checks_lib_none.dart' as libNone;
import 'late_field_checks_lib_trust.dart' as libTrust;
import 'late_field_checks_lib_check.dart' as libCheck;

void main() {
  libraryName = null;
  libNone.main();
  Expect.equals('LibraryNone', libraryName);

  libraryName = null;
  libCheck.main();
  Expect.equals('LibraryCheck', libraryName);

  libraryName = null;
  libTrust.main();
  Expect.equals('LibraryTrust', libraryName);
}
