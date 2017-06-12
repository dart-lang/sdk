// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Base {
  baseFoo() {
    print('Base.baseFoo()');
    return 1;
  }

  foo() {
    print('Base.foo()');
    return 1;
  }
}

class Mixin {
  mixinFoo() {
    print('Mixin.mixinFoo()');
    return 2;
  }

  foo() {
    print('Mixin.foo()');
    return 2;
  }
}

class Mixin2 {
  mixin2Foo() {
    print('Mixin2.mixin2Foo()');
    return 3;
  }

  foo() {
    print('Mixin2.foo()');
    return 3;
  }
}

class Sub extends Base with Mixin, Mixin2 {
  subFoo() {
    print('Sub.subFoo()');
    return 4;
  }

  foo() {
    print('Sub.foo()');
    return 4;
  }
}

main() {
  var o = new Sub();

  Expect.isTrue(o.baseFoo() == 1);
  Expect.isTrue(o.mixinFoo() == 2);
  Expect.isTrue(o.mixin2Foo() == 3);
  Expect.isTrue(o.subFoo() == 4);
  Expect.isTrue(o.foo() == 4);
}
