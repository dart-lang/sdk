// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when mixing in a regular class inside its library.

class Class {
  int foo = 0;
}

mixin Mixin {
  int foo = 0;
}

abstract class A with Class {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class B with Class {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class C = Object with Class;
// ^
// [analyzer] unspecified
// [cfe] unspecified

abstract class D with Class, Mixin {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class E with Class, Mixin {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class NamedMixinClassApplication = Object with Class;
// ^
// [analyzer] unspecified
// [cfe] unspecified
