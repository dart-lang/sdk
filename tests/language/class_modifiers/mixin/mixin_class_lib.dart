// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin class Class {
  int foo = 0;
}

abstract mixin class AbstractMixinClass {
  int foo = 0;
}

mixin Mixin {
  int foo = 0;
}
mixin class NamedMixinClassApplication = Object with Mixin;

class NotAMixinClass {}

abstract class NotAnAbstractMixinClass {}

class NotANamedMixinClassApplication = Object with Mixin;
