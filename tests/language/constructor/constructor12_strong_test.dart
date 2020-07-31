// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

// Copied from constructor12_test.dart to break out a single expectation that
// is different in weak and strong modes.

import "package:expect/expect.dart";

import 'constructor12_lib.dart';

main() {
  var a2 = confuse(new A(2));
  Expect.isFalse(a2 is A<Object>);
}
