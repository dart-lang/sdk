// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// An in-body declaring constructor in an extension type can have additional
// parameters, as long as exactly one parameter is declaring and is `final`.

// SharedOptions=--enable-experiment=declaring-constructors

import 'package:expect/expect.dart';

extension type ET1 {
  this(final int i);
}

extension type ET2 {
  this(int i, final int x);
}

extension type ET3 {
  this(int i, final x);
}

extension type ET4 {
  this(final i);
}

void main() {
  Expect.equals(1, ET1(1).i);
  Expect.equals(2, ET2(1, 2).x);
  Expect.equals(2, ET3(1, 2).x);
  Expect.equals(1, ET4(1).i);
}
