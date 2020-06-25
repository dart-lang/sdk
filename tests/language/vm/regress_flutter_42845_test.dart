// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=extension-methods

// Tests exported extensions.

import "regress_flutter_42845_lib.dart";
export "regress_flutter_42845_lib.dart" show TestExtension, UnusedExtension;

import "package:expect/expect.dart";

int i = 42;

void main() {
  Expect.isTrue(i.isPositive);
  Expect.isFalse(i.isNegative);
}
