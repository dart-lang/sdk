// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test checking that null is handled correctly at the call-sites that
// are tracking static type exactness.

// Requirements=nnbd-weak

import 'package:expect/expect.dart';

void invokeAdd(List<int> l) {
  l.add(10);
}

void main() {
  dynamic myNull;
  Expect.throws(() => invokeAdd(myNull), (error) => error is NoSuchMethodError);
}
