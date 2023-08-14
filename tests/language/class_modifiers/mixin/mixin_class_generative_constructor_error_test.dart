// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when applying the mixin modifier to a class that declares a generative
// constructor

mixin class MixinClass {
  final int foo;

  MixinClass(this.foo);
//^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
// [cfe] Can't use 'MixinClass' as a mixin because it has constructors.
}

mixin class MixinClassNamed {
  final int foo;

  MixinClassNamed.named(this.foo);
//^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
// [cfe] Can't use 'MixinClassNamed' as a mixin because it has constructors.
}

mixin class MixinClassRedirect {
  int foo = 0;

  MixinClassRedirect.named(int f) { this.foo = f; }
//^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
// [cfe] Can't use 'MixinClassRedirect' as a mixin because it has constructors.

  MixinClassRedirect.x(int f) : this.named(f);
//^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
// [cfe] Can't use 'MixinClassRedirect' as a mixin because it has constructors.
}

mixin class MixinClassExternal {
  external MixinClassExternal();
//         ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
// [cfe] Can't use 'MixinClassExternal' as a mixin because it has constructors.
}

mixin class MixinClassSuper {
  MixinClassSuper(): super();
//^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
// [cfe] Can't use 'MixinClassSuper' as a mixin because it has constructors.
}

mixin class MixinClassBody {
  MixinClassBody() {}
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
// [cfe] Can't use 'MixinClassBody' as a mixin because it has constructors.
}

class GenerativeConstructor with MixinClass {}
