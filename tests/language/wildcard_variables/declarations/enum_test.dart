// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the usage of wildcards in enum constructors and fields.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';

enum A { _ }

enum B {
  e(2);

  const B(int _) : _ = 1;

  final int _;
}

void main() {
  A._;
  Expect.equals(1, B.e._);
}
