// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Verifies that `quote` is not null after a deoptimization in the loop.

// VMOptions=--optimization_counter_threshold=100 --no-background_compilation --no-use-osr

import 'package:expect/expect.dart';

class A {
  int f() => 1;
}

class B extends A {
  @override
  int f() => 2;
}

// Returns the index of the closing quote.
@pragma('vm:never-inline')
int closingQuote(String text, A a) {
  var i = 0;
  final quote = text[i++];
  while (i < text.length && text[i] != quote) {
    i++;
    a.f(); // Deoptimizes the first time `a` is a B.
  }
  return i;
}

void main() {
  for (var k = 0; k < 1000; k++) {
    Expect.equals(3, closingQuote('"ab"', A()));
  }
  Expect.equals(3, closingQuote('"ab"', B()));
}
