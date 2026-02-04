// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when applying the mixin modifier to a class that declares a generative
// constructor

mixin class MixinClass {
  final int foo;

  MixinClass(this.foo);
  // [error column 3, length 10]
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
  // [cfe] Can't use 'MixinClass' as a mixin because it has constructors.
}

mixin class MixinClassNamed {
  final int foo;

  MixinClassNamed.named(this.foo);
  // [error column 3, length 21]
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
  // [error column 3, length 15]
  // [cfe] Can't use 'MixinClassNamed' as a mixin because it has constructors.
}

mixin class MixinClassRedirect {
  int foo = 0;

  MixinClassRedirect.named(int f) {
  // [error column 3, length 24]
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
  // [error column 3, length 18]
  // [cfe] Can't use 'MixinClassRedirect' as a mixin because it has constructors.
    this.foo = f;
  }

  MixinClassRedirect.x(int f) : this.named(f);
  // [error column 3, length 20]
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
  // [error column 3, length 18]
  // [cfe] Can't use 'MixinClassRedirect' as a mixin because it has constructors.
}

mixin class MixinClassExternal {
  external MixinClassExternal();
  //       ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
  // [cfe] Can't use 'MixinClassExternal' as a mixin because it has constructors.
}

mixin class MixinClassSuper {
  MixinClassSuper() : super();
  // [error column 3, length 15]
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
  // [cfe] Can't use 'MixinClassSuper' as a mixin because it has constructors.
}

mixin class MixinClassBody {
  MixinClassBody() {}
  // [error column 3, length 14]
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
  // [cfe] Can't use 'MixinClassBody' as a mixin because it has constructors.
}

class GenerativeConstructor with MixinClass {}
