// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the interactions between a wildcard top-level function, which is
// binding, with local non-binding wildcard variables.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';

int _(int _) => 2;

void main() {
  int _ = 1;
  const _ = 1;
  int _() => 1;
  Expect.equals(2, _(1));
}

class Clas<_> {
  void member<_>() {
    int _ = 1;
    const _ = 1;
    int _() => 1;
    Expect.equals(2, _(1));
  }
}
