// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../native_testing.dart';
import 'null_assertions_lib.dart';

// Implementation of `JSInterface` except in a folder that is not part of the
// allowlist for the `--native-null-assertions` flag. This file is not treated
// as a web library, and therefore the `JS()` invocations should not be checked.

@Native('CCCInNonWebLibrary')
class CCCInNonWebLibrary implements JSInterface {
  String get name => JS('String', '#.name', this);
  String? get optName => JS('String|Null', '#.optName', this);
}
