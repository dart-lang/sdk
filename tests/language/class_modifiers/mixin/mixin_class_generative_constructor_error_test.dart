// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when applying the mixin modifier to a class that declares a generative
// constructor

mixin class MixinClass {
// ^
// [analyzer] unspecified
// [cfe] unspecified
  final int foo;

  MixinClass(this.foo);
}

class GenerativeConstructor with MixinClass {}
