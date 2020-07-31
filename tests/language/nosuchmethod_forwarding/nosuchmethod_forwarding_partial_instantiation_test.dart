// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing that `noSuchMethod` forwarders can be partially instantiated, and
// that their delayed type arguments are transparently passed to `noSuchMethod`.

import 'package:expect/expect.dart';

class C {
  T test1<T>(T x);

  dynamic noSuchMethod(Invocation invoke) {
    Expect.equals(invoke.typeArguments.length, 1);
    Expect.equals(invoke.typeArguments[0].toString(), 'int');
    Expect.equals(invoke.positionalArguments[0], 1);
    return 1;
  }
}

void main() {
  var c = new C();
  int Function(int) k1 = c.test1;
  k1(1);
}
