// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Other-library declarations used by
// final_mixin_typedef_with_outside_error_test.dart.

final mixin FinalMixin {
  int foo = 0;
}

typedef FinalMixinTypeDef = FinalMixin;

final class A with FinalMixinTypeDef {
  int foo = 1;
}
