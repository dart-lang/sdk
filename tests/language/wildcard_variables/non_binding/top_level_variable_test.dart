// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the interactions between a wildcard top-level variable, which is
// binding, with local non-binding wildcard variables.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';

var _ = 2;

void main() {
  Clas().member(); // Top level _ is 4 after this call.
  _ = 2;

  int _ = _;
  int _ = 3;
  var (_, _) = (3, '4');
  Expect.equals(2, _);

  _ = 4;
  Expect.equals(4, _);
}

class Clas<_> {
  void member<_>() {
    int _ = _;
    int _ = 3;
    var (_, _) = (3, '4');
    Expect.equals(2, _);

    _ = 4;
    Expect.equals(4, _);

    int foo<_>([int _ = 5]) => _;
    Expect.equals(4, foo());
  }
}
