// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.7

// Requirements=nnbd-weak

import "package:expect/expect.dart";

main() {
  // In legacy Dart 2 and null safety weak mode the error handlers can
  // return null.
  Expect.equals(null, int.parse("foo", onError: (_) => null));
  Expect.equals(null, double.parse("foo", (_) => null));
}
