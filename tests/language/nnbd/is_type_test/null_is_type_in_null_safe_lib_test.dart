// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Can't run in strong mode since it contains a legacy library.
// Requirements=nnbd-weak

import 'package:expect/expect.dart';
import 'legacy_library.dart';

// Type tests (is checks) located in a null safe library.
main() {
  Expect.isFalse(null is Never);
  // `null is Never*`
  Expect.isTrue(nullSafeIsLegacy<Never>(null));
  Expect.isTrue(null is Never?);
  Expect.isTrue(null is Null);
  Expect.isFalse(null is int);
  // `null is int*`
  Expect.isFalse(nullSafeIsLegacy<int>(null));
  Expect.isTrue(null is int?);
  Expect.isFalse(null is Object);
  // `null is Object*`
  Expect.isTrue(nullSafeIsLegacy<Object>(null));
  Expect.isTrue(null is Object?);
  Expect.isTrue(null is dynamic);
}
