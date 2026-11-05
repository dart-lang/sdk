// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Anonymous methods should have a separate notion of `this` from the containing
// method.

// SharedOptions=--enable-experiment=anonymous-methods --enable-experiment=this-promotion

import '../../static_type_helper.dart';

class C {
  void test() {
    try {
      this.expectStaticType<Exactly<C>>;
      this as D;
      this.expectStaticType<Exactly<D>>;
      C().=> [
        this.expectStaticType<Exactly<C>>,
        this as E,
        this.expectStaticType<Exactly<E>>,
      ];
      this.expectStaticType<Exactly<D>>;
    } catch (TypeError) {}
  }
}

class D extends C {}

class E extends C {}

class F extends D implements E {}

void main() {
  C().test();
  D().test();
  E().test();
  F().test();
}
