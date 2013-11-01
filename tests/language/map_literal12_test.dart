// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing the instanceof operation.

import "package:expect/expect.dart";

main() {
  var x = <int, String>{};
  Expect.isTrue(x is Map<int, String>);
  Expect.isFalse(x is Map<double, String>);
  Expect.isFalse(x is Map<int, double>);
}
