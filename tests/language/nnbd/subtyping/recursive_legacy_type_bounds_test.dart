// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Can't run in strong mode since it contains a legacy library.
// Requirements=nnbd-weak

import 'package:expect/expect.dart';

import 'recursive_legacy_type_bounds_lib.dart';

main() {
  dynamic classWithRecursiveLegacyTypeBoundsInSupertype = Legacy_A();
  Expect.isTrue(classWithRecursiveLegacyTypeBoundsInSupertype is Legacy_C);
}
