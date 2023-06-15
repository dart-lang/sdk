// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow base mixins/classes to be subtyped by base, final, or sealed
// classes/mixins and produce no error.

import 'package:expect/expect.dart';

base class BaseClass {
  int foo = 0;
}

base mixin BaseMixin {
  int foo = 0;
}

base class BaseExtends extends BaseClass {}

final class FinalExtends extends BaseClass {}

sealed class SealedExtends extends BaseClass {}

base class SealedExtendsImpl extends SealedExtends {}

base class BaseImplements implements BaseClass {
  int foo = 0;
}

final class FinalImplements implements BaseClass {
  int foo = 0;
}

sealed class SealedImplements implements BaseClass {
  int foo = 0;
}

base class SealedImplementsImpl extends SealedImplements {}

base mixin BaseMixinImplements implements BaseMixin {}

base class ImplementsImpl implements BaseMixinImplements {
  int foo = 0;
}

base class BaseWith with BaseMixin {}

final class FinalWith with BaseMixin {}

sealed class SealedWith with BaseMixin {}

base class SealedWithImpl extends SealedWith {}

base mixin BaseOn on BaseClass {}

base class OnImpl implements BaseOn {
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
  Expect.equals(0, ImplementsImpl().foo);
  Expect.equals(0, BaseWith().foo);
  Expect.equals(0, FinalWith().foo);
  Expect.equals(0, SealedWithImpl().foo);
  Expect.equals(0, OnImpl().foo);
  Expect.equals(0, EnumWith.x.index);
  Expect.equals(0, EnumImplements.x.index);
}
