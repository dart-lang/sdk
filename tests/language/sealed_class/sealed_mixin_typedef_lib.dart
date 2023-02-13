// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Other-library declarations used by sealed_mixin_typedef_test.dart.

sealed mixin SealedMixin {
  int foo = 0;
}

typedef SealedMixinTypeDef = SealedMixin;

class A with SealedMixinTypeDef {}
