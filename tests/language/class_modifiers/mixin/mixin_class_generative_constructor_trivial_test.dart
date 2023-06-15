// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow trivial generative constructors in mixin classes.

import 'package:expect/expect.dart';

mixin class MixinClassCtor {
  int foo = 0;
  MixinClassCtor();
  MixinClassCtor.named();
}

mixin class ConstMixinClassCtor {
  final int foo = 0;
  const ConstMixinClassCtor();
  const ConstMixinClassCtor.named();
}

mixin class MixinClassFactory {
  int foo = 0;
  MixinClassFactory();
  MixinClassFactory.named();
  factory MixinClassFactory.x() = MixinClassFactory.named;
  factory MixinClassFactory.y() = MixinClassFactory;
  factory MixinClassFactory.z() { return MixinClassFactory(); }
}


main() {
  Expect.equals(0, MixinClassCtor().foo);
  Expect.equals(0, MixinClassCtor.named().foo);
  Expect.equals(0, ConstMixinClassCtor().foo);
  Expect.equals(0, ConstMixinClassCtor.named().foo);
  Expect.equals(0, MixinClassFactory.x().foo);
  Expect.equals(0, MixinClassFactory.y().foo);
  Expect.equals(0, MixinClassFactory.z().foo);
}
