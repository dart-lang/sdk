// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A mixin declaration cannot declare any constructors,
// including factory constructors.
// A mixin class declaration cannot declare any non-factory, non-trivial
// constructors.

class A {}

class B implements M, N {
  const B();
}

mixin M on A {
  factory M.foo() => throw "uncalled";
  // [error column 3, length 7]
  // [analyzer] SYNTACTIC_ERROR.MIXIN_DECLARES_CONSTRUCTOR
  // [cfe] Mixins can't declare constructors.
  const factory M.bar() = B;
  //    ^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.MIXIN_DECLARES_CONSTRUCTOR
  // [cfe] Mixins can't declare constructors.
  M.baz();
  // [error column 3, length 1]
  // [analyzer] SYNTACTIC_ERROR.MIXIN_DECLARES_CONSTRUCTOR
  // [cfe] Mixins can't declare constructors.
  M.qux() : this.baz();
  // [error column 3, length 1]
  // [analyzer] SYNTACTIC_ERROR.MIXIN_DECLARES_CONSTRUCTOR
  // [cfe] Mixins can't declare constructors.
}

class MA extends A with M {}
//    ^
// [cfe] Can't use 'M' as a mixin because it has constructors.

mixin class N {
  // It's OK for a mixin derived from a class to have factory constructors
  // and trivial non-redirecting generative constructors.
  // (Trivial means: No initializer list, no body, no parameters.
  // That is, anything which does anything, and can't be ignored.)
  factory N.foo() => const B();
  const factory N.bar() = B;
  const N.baz();
}

mixin class NE {
  const NE.baz();
  // Not generative constructors that has initializer lists or bodies,
  // or is forwarding. Anything that contains any user code.

  const NE.qux(): this.baz(); // Is forwarding.
  //    ^^
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
  // [cfe] Can't use 'NE' as a mixin because it has constructors.

  NE.param(int i);
  // [error column 3, length 2]
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
  // [cfe] Can't use 'NE' as a mixin because it has constructors.

  const NE.init() : assert(true, "has initializer list");
  //    ^^
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
  // [cfe] Can't use 'NE' as a mixin because it has constructors.

  external NE.ext();
  //       ^^
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
  // [cfe] Can't use 'NE' as a mixin because it has constructors.

  NE.body() {
  // [error column 3, length 2]
  // [analyzer] COMPILE_TIME_ERROR.MIXIN_CLASS_DECLARES_CONSTRUCTOR
  // [cfe] Can't use 'NE' as a mixin because it has constructors.
    print("Did something");
  }
}

class NA = A with N;
class NAE = A with NE;

main() {
  // Constructors of mixin are not inherited by application.
  NA.foo();
  // ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] Member not found: 'NA.foo'.
  NA.bar();
  // ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] Member not found: 'NA.bar'.
  NA.baz();
  // ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] Member not found: 'NA.baz'.
}
