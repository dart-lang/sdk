// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Extension types are allowed to have non-redirecting generative constructors,
// implicitly or explicitly initializing the representation variable.

// SharedOptions=--enable-experiment=primary-constructors

import "package:expect/expect.dart";

extension type ET1(int x) {
  ET1.named(this.x);
  ET1.other(int y) : x = y;
}

void main() {
  var e1 = ET1.named(1);
  Expect.equals(1, e1.x);

  var e2 = ET1.other(2);
  Expect.equals(2, e2.x);
}
