// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `late` and `external` must be initialized in the body.

// SharedOptions=--enable-experiment=primary-constructors

import "package:expect/expect.dart";

class C1(this.x) {
  late int x;
  external double d;
}

void main() {
  Expect.equals(1, C1(1).x);
}
