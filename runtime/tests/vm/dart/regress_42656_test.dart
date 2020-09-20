// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that mixin deduplication correctly handles identical anonymous
// mixins from opt-in and opt-out libraries.
// Regression test for https://github.com/dart-lang/sdk/issues/42656.

// Requirements=nnbd-weak

import 'package:expect/expect.dart';
import 'regress_42656_opt_in_lib.dart';
import 'regress_42656_opt_out_lib.dart';

void main() {
  Expect.equals('MixinA', C2().toString());
  Expect.equals('MixinB', D2().toString());
  Expect.equals('MixinA', E2().toString());
  Expect.equals('MixinB', F2().toString());
  Expect.isFalse(C2() == C2());
  Expect.isFalse(D2() == D2());
  Expect.isFalse(E2() == E2());
  Expect.isFalse(F2() == F2());
  Expect.equals(42, C2().x);
  Expect.equals(3, D2().y);
  Expect.equals(42, E2().x);
  Expect.equals(3, F2().y);
}
