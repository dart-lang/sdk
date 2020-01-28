// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/38035.
//
// Verifies that static tear-off has correct information about argument types.

import 'package:expect/expect.dart';
import 'dart:mirrors';

class A {
  static bool _defaultCheck([dynamic e]) => true;
}

main() {
  Expect.equals('([dynamic]) -> dart.core.bool',
      MirrorSystem.getName(reflect(A._defaultCheck).type.simpleName));
}
