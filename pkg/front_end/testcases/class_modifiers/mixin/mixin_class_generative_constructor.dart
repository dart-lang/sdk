// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin class ErrorMixinClass {
  final int foo;
  ErrorMixinClass(this.foo); /* Error */
}

mixin class ErrorMixinClassNamed {
  final int foo;
  ErrorMixinClassNamed.named(this.foo); /* Error */
}

mixin class ErrorMixinClassRedirect {
  int foo = 0;
  ErrorMixinClassRedirect.named(int f) { this.foo = f; } /* Error */
  ErrorMixinClassRedirect.x(int f) : this.named(f); /* Error */
  ErrorMixinClassRedirect() {} /* Error */
}

mixin class ErrorMixinClassExternal {
  external ErrorMixinClassExternal(); /* Error */
}

mixin class ErrorMixinClassSuper {
  ErrorMixinClassSuper(): super(); /* Error */
}

mixin class ErrorMixinClassBody {
  ErrorMixinClassBody() {} /* Error */
}

mixin class MixinClassConstructor {
  int foo = 0;
  MixinClassConstructor(); /* Ok */
  MixinClassConstructor.named(); /* Ok */
}

mixin class ConstMixinClassConstructor {
  final int foo = 0;
  const ConstMixinClassConstructor(); /* Ok */
  const ConstMixinClassConstructor.named(); /* Ok */
}

mixin class MixinClassFactory {
  int foo = 0;
  MixinClassFactory(); /* Ok */
  MixinClassFactory.named(); /* Ok */
  factory MixinClassFactory.x() = MixinClassFactory.named; /* Ok */
  factory MixinClassFactory.y() = MixinClassFactory; /* Ok */
  factory MixinClassFactory.z() { return MixinClassFactory(); } /* Ok */
}
