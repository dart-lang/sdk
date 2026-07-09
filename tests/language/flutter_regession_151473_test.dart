// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

abstract class I {
  Base foo();
  Base get bar;
}

abstract class A extends I {
  Base foo() => Sub1();
  Base get bar => Sub1();
}

class B1 extends A {
  Base foo() {
    print(super.foo());
    return Sub2();
  }

  Base get bar {
    print(super.bar);
    return Sub2();
  }
}

class B2 extends A {
  Base foo() {
    print(super.foo());
    return Sub3();
  }

  Base get bar {
    print(super.bar);
    return Sub3();
  }
}

abstract class Base {}

class Sub1 extends Base {}

class Sub2 extends Base {}

class Sub3 extends Base {}

main() {
  final l = [B1(), B2()];
  Expect.isTrue(l[0].foo() is Sub2);
  Expect.isTrue(l[0].bar is Sub2);
}
