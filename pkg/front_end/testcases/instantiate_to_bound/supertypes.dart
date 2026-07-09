// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks that instantiate to bound is applied to raw generic
// supertypes.

import 'package:expect/expect.dart';

class B {}

class X<T extends B> {}

class Y extends X {}

void main() {
  Expect.isTrue(new Y() is X);
}
