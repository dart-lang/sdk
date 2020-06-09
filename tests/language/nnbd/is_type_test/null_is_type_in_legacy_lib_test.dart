// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opt out of Null Safety:
// @dart = 2.6

// Can't run in strong mode since it contains a legacy library.
// Requirements=nnbd-weak

import 'package:expect/expect.dart';
import 'null_safe_library.dart';

// Type tests (is checks) located in a legacy library.
main() {
  // `null is Never*`
  Expect.isTrue(null is Never);
  // `null is Never?`
  Expect.isTrue(legacyIsNullable<Never>(null));
  Expect.isTrue(null is Null);
  // `null is int*`
  Expect.isFalse(null is int);
  // `null is int?`
  Expect.isTrue(legacyIsNullable<int>(null));
  // `null is Object*`
  Expect.isTrue(null is Object);
  // `null is Object?`
  Expect.isTrue(legacyIsNullable<Object>(null));
  Expect.isTrue(null is dynamic);
}
