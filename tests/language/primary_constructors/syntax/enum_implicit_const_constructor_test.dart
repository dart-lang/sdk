// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// With the primary constructors feature, generative constructors in enums are
// implicitly const and don't require the `const` keyword.

// SharedOptions=--enable-experiment=primary-constructors

import 'package:expect/expect.dart';

enum E1 {
  e;
  new ();
}

enum E2(final int x) {
  e1(1),
  e2.named(2);

  new named(int x) : this(x);
}

enum E3 {
  e1,
  e2.named(2);

  final int x;
  new () : this.named(1);
  new named(this.x);
}

enum E4 {
  e1,
  e2.named(2);

  final int x;
  E4() : this.named(1);
  E4.named(this.x);
}

void main() {
  Expect.equals(E1.e, E1.e);

  Expect.equals(1, E2.e1.x);
  Expect.equals(2, E2.e2.x);

  Expect.equals(1, E3.e1.x);
  Expect.equals(2, E3.e2.x);

  Expect.equals(1, E4.e1.x);
  Expect.equals(2, E4.e2.x);
}
