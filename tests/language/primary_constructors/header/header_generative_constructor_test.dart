// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A class that has a declaring header constructor can have redirecting
// generative constructors and factory constructors.

// SharedOptions=--enable-experiment=primary-constructors

import 'package:expect/expect.dart';

class C1(final int x) {
  C1.redirecting(int x): this(x);
}

class C2.named(final int x) {
  C2.redirecting(int x): this.named(x);
}

class C3(final int x) {
  factory C3.from(int value) => C3(value * 2);
}

void main() {
  Expect.equals(1, C1.redirecting(1).x);
  Expect.equals(2, C2.redirecting(2).x);
  Expect.equals(6, C3.from(3).x);
}
