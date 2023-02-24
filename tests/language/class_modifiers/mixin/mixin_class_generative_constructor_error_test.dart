// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when applying the mixin modifier to a class that declares a generative
// constructor

mixin class MixinClass {
//          ^
// [cfe] Can't use 'MixinClass' as a mixin because it has constructors.
  final int foo;

  MixinClass(this.foo);
//^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
}

mixin class MixinClassNamed {
//          ^
// [cfe] Can't use 'MixinClassNamed' as a mixin because it has constructors.
  final int foo;

  MixinClassNamed.named(this.foo);
//^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
}

mixin class MixinClassRedirect {
//          ^
// [cfe] Can't use 'MixinClassRedirect' as a mixin because it has constructors.
  int foo = 0;

  MixinClassRedirect.named(int f) { this.foo = f; }
//^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR

  MixinClassRedirect.x(int f) : this.named(f);
//^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
}

mixin class MixinClassExternal {
//          ^
// [cfe] Can't use 'MixinClassExternal' as a mixin because it has constructors.
  external MixinClassExternal();
//         ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
}

mixin class MixinClassSuper {
//          ^
// [cfe] Can't use 'MixinClassSuper' as a mixin because it has constructors.
  MixinClassSuper(): super();
//^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
}

mixin class MixinClassBody {
//          ^
// [cfe] Can't use 'MixinClassBody' as a mixin because it has constructors.
  MixinClassBody() {}
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
}

class GenerativeConstructor with MixinClass {}
