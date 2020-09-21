// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.8

// Requirements=nnbd-weak

/// Test that a legacy class with an implicit superclass constructor is allowed
/// to call a null safe class's constructor with required named parameters.
import 'package:expect/expect.dart';
import 'legacy_implicit_super_constructor_lib.dart';

class Legacy extends NullSafe {}

main() {
  var legacy = Legacy();
  Expect.isNull(legacy.i);
  Expect.isNull(legacy.s);
}
