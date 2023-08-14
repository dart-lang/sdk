// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library declarations used by 
// base_mixin_typedef_with_outside_test.dart and
// base_mixin_typedef_with_test.dart.

base mixin BaseMixin {
  int foo = 0;
}

typedef BaseMixinTypeDef = BaseMixin;

base class A with BaseMixinTypeDef {
  int foo = 1;
}
