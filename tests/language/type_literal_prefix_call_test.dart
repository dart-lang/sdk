// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:core' as core;

// Check that calling a type with a prefix is allowed, but throws at runtime.

main() {
  Expect.throws(() => core.List(), (e) => e is core.NoSuchMethodError);
}
