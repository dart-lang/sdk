// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

class Class {
  int foo = 0;
}

mixin Mixin {
  int foo = 0;
}

abstract class AbstractClass {}

class NamedMixinClassApplication = Object with Mixin;
