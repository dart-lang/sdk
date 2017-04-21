// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that otherwise unused intercepted methods are reified correctly.  This
/// was a bug in dart2js.
library test.is_odd_test;

@MirrorsUsed(targets: const ["test.is_odd_test", "isOdd", "int"])
import 'dart:mirrors';

import 'package:expect/expect.dart';

main() {
  Expect.isTrue(reflect(1).getField(#isOdd).reflectee);
  Expect.isFalse(reflect(2).getField(#isOdd).reflectee);
}
