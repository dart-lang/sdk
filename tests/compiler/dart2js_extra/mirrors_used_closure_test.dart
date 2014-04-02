// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library MirrorsTest;

import 'package:expect/expect.dart';

@MirrorsUsed(targets: const ['A.foo', 'B.bar'])
import 'dart:mirrors';

class A {
  foo() => 42;
  bar() => 499;
}

class B {
  bar() => 33;
}

// Uses DateTime.now to make it impossible to predict.
// Uses recursive call to make it harder to inline.
confuse(x) {
  if (new DateTime.now().millisecondsSinceEpoch == 42) return confuse(x + 1);
  return x;
}

main() {
  var f = [new A(), new B()][confuse(0)].bar;
  Expect.throws(() => reflect(f).invoke(#call, [], {}),
                (e) => e is UnsupportedError);
}
