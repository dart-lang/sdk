// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

// Can't run in strong mode since it contains a legacy library.
// Requirements=nnbd-weak

import 'package:expect/expect.dart';

import 'futureOr_normalization_legacy_lib.dart' as legacy;
import 'futureOr_normalization_null_safe_lib.dart';

main() {
  // Object* == FutureOr<Object*>
  Expect.equals(legacy.object, legacy.nonNullableFutureOrOfLegacyObject());
}
