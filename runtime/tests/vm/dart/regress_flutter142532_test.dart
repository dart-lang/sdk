// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/142532.

// VMOptions=--deterministic --optimization-counter-threshold=1000

import 'package:expect/expect.dart';

abstract class C {
  String str();
}

class A extends C {
  String str() => 'A!';
}

class B extends C {
  String str() => 'B!';
}

class N {
  final C x;
  late C v = x;

  N(this.x);

  @pragma('vm:never-inline')
  void foo() {
    Expect.equals(v.str(), x.str());
  }
}

void main() {
  final ns = [N(A()), N(B())];

  // Init fields through late field initializer. This does not update guarded cid
  for (var n in ns) n.v;

  // Update field normally. This will set guarded cid to be monomorphic (A)
  ns[0].v = ns[0].x;

  for (var i = 0; i < 10000; i++) {
    for (var n in ns) n.foo();
  }
}
