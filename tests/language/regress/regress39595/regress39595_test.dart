// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for https://github.com/dart-lang/sdk/issues/39595.
///
/// Libraries with the names 'true', 'false', and 'null' should not shadow
/// those terms.
import 'package:expect/expect.dart';

import 'true.dart';
import 'false.dart';
import 'null.dart';

main() {
  Expect.equals('from a library named "true"', fromTrue);
  Expect.equals('from a library named "false"', fromFalse);
  Expect.equals('from a library named "null"', fromNull);
}
