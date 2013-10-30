// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type inference sees the call to `fisk` from the mirror system
// and not infers the argument to be an integer.
library test;

@MirrorsUsed(targets: 'fisk', override: '*')
import 'dart:mirrors';

import 'package:expect/expect.dart';

bool fisk(a) => a is int;

main() {
  Expect.isTrue(fisk(1));
  var lm = currentMirrorSystem().findLibrary(const Symbol('test'));
  Expect.isFalse(lm.invoke(const Symbol('fisk'), ['hest']).reflectee);
}
