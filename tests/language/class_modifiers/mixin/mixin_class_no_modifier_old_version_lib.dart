// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.19

// Testing usage of classes as mixins with no 'mixin' modifier in an older
// version.

class Class {
  int foo = 0;
}

mixin Mixin {
  int foo = 0;
}

abstract class AbstractClass {
  int foo = 0;
}

class NamedMixinClassApplication = Object with Mixin;

class GenerativeConstructorClass {
  final int foo;

  GenerativeConstructorClass(this.foo);
}

class NonObjectSuperclassClass extends Class {}
