// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

interface mixin InterfaceMixin {
  int foo = 0;
}

typedef InterfaceMixinTypeDef = InterfaceMixin;

class A with InterfaceMixinTypeDef {
  @override
  int foo = 1;
}
