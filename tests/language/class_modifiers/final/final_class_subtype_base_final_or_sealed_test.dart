// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow final mixins/classes to be subtyped by base, final, or sealed
// classes/mixins and produce no error.

import 'package:expect/expect.dart';

final class FinalClass {
  int foo = 0;
}

base class BaseExtends extends FinalClass {}

final class FinalExtends extends FinalClass {}

sealed class SealedExtends extends FinalClass {}

final class SealedExtendsImpl extends SealedExtends {}

base class BaseImplements implements FinalClass {
  int foo = 0;
}

final class FinalImplements implements FinalClass {
  int foo = 0;
}

sealed class SealedImplements implements FinalClass {
  int foo = 0;
}

final class SealedImplementsImpl extends SealedImplements {}

base mixin BaseOn on FinalClass {}

final class OnImpl implements BaseOn {
  int foo = 0;
}

base mixin MixinForEnum {}

enum EnumWith with MixinForEnum { x }

enum EnumImplements implements MixinForEnum { x }

main() {
  Expect.equals(0, BaseExtends().foo);
  Expect.equals(0, FinalExtends().foo);
  Expect.equals(0, SealedExtendsImpl().foo);
  Expect.equals(0, BaseImplements().foo);
  Expect.equals(0, FinalImplements().foo);
  Expect.equals(0, SealedImplementsImpl().foo);
  Expect.equals(0, OnImpl().foo);
  Expect.equals(0, EnumWith.x.index);
  Expect.equals(0, EnumImplements.x.index);
}
