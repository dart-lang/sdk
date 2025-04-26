// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing erroneous ways of using shorthands with the `==` and `!=` operators.

// SharedOptions=--enable-experiment=dot-shorthands

import '../dot_shorthand_helper.dart';

class ConstConstructorAssert {
  const ConstConstructorAssert.regular(ConstructorClass ctor)
    : assert(const .constRegular(1) == ctor);
  //                ^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constRegular'.

  const ConstConstructorAssert.named(ConstructorClass ctor)
    : assert(const .constNamed(x: 1) == ctor);
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constNamed'.

  const ConstConstructorAssert.optional(ConstructorClass ctor)
    : assert(const .constOptional(1) == ctor);
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constOptional'.

  const ConstConstructorAssert.regularExt(ConstructorExt ctor)
    : assert(const .constRegular(1) == ctor);
  //                ^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constRegular'.

  const ConstConstructorAssert.namedExt(ConstructorExt ctor)
    : assert(const .constNamed(x: 1) == ctor);
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constNamed'.

  const ConstConstructorAssert.optionalExt(ConstructorExt ctor)
    : assert(const .constOptional(1) == ctor);
  //                ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constOptional'.
}

void notSymmetrical(ConstructorClass ctor, ConstructorExt ctorExt) {
  const ConstructorClass constCtor = .constRegular(1);
  const bool symEqRegular = .constRegular(1) == constCtor;
  //                         ^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constRegular'.

  const bool symEqNamed = .constNamed(x: 1) == constCtor;
  //                       ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constNamed'.

  const bool symEqOptional = .constOptional(1) == constCtor;
  //                          ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constOptional'.

  const bool symNeqRegular = .constRegular(1) != constCtor;
  //                          ^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constRegular'.

  const bool symNeqNamed = .constNamed(x: 1) != constCtor;
  //                        ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constNamed'.

  const bool symNeqOptional = .constOptional(1) != constCtor;
  //                           ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constOptional'.

  const ConstructorExt constCtorExt = .constRegular(1);
  const bool symExtEqRegular = .constRegular(1) == constCtorExt;
  //                            ^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constRegular'.

  const bool symExtEqNamed = .constNamed(x: 1) == constCtorExt;
  //                          ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constNamed'.

  const bool symExtEqOptional = .constOptional(1) == constCtorExt;
  //                             ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constOptional'.

  const bool symExtNeqRegular = .constRegular(1) != constCtorExt;
  //                             ^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constRegular'.

  const bool symExtNeqNamed = .constNamed(x: 1) != constCtorExt;
  //                           ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constNamed'.

  const bool symExtNeqOptional = .constOptional(1) != constCtorExt;
  //                              ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constOptional'.

  if (.new(1) == ctor) print('not ok');
  //   ^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'new'.

  if (.regular(1) == ctor) print('not ok');
  //   ^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'regular'.

  if (.named(x: 1) == ctor) print('not ok');
  //   ^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'named'.

  if (.optional(1) == ctor) print('not ok');
  //   ^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'optional'.

  if (.new(1) != ctor) print('not ok');
  //   ^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'new'.

  if (.regular(1) != ctor) print('not ok');
  //   ^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'regular'.

  if (.named(x: 1) != ctor) print('not ok');
  //   ^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'named'.

  if (.optional(1) != ctor) print('not ok');
  //   ^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'optional'.

  if (.new(1) == ctorExt) print('not ok');
  //   ^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'new'.

  if (.regular(1) == ctorExt) print('not ok');
  //   ^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'regular'.

  if (.named(x: 1) == ctorExt) print('not ok');
  //   ^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'named'.

  if (.optional(1) == ctorExt) print('not ok');
  //   ^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'optional'.

  if (.new(1) != ctorExt) print('not ok');
  //   ^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'new'.

  if (.regular(1) != ctorExt) print('not ok');
  //   ^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'regular'.

  if (.named(x: 1) != ctorExt) print('not ok');
  //   ^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'named'.

  if (.optional(1) != ctorExt) print('not ok');
  //   ^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'optional'.
}

void rhsNeedsToBeShorthand(
  ConstructorClass ctor,
  ConstructorExt ctorExt,
  bool condition,
) {
  const Object obj = true;
  const bool constCondition = obj as bool;

  const ConstructorClass constCtor = .constRegular(1);
  const bool rhsCtorEq = constCtor == (constCondition ? .constRegular(1) : ConstructorClass.constNamed(x: 1));
  //                                                     ^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constRegular'.

  const bool rhsCtorNeq = constCtor != (constCondition ? ConstructorClass.constOptional(1) : .constRegular(1));
  //                                                                                          ^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constRegular'.

  if (ctor == (.new(1))) {
    //          ^^^
    // [analyzer] unspecified
    // [cfe] No type was provided to find the dot shorthand 'new'.
    print('not ok');
  }

  if (ctor != (.new(1))) {
    //          ^^^
    // [analyzer] unspecified
    // [cfe] No type was provided to find the dot shorthand 'new'.
    print('not ok');
  }

  if (ctor == (condition ? .new(1) : .regular(1))) {
    //                      ^^^
    // [analyzer] unspecified
    // [cfe] No type was provided to find the dot shorthand 'new'.
    //                                ^^^^^^^
    // [analyzer] unspecified
    // [cfe] No type was provided to find the dot shorthand 'regular'.
    print('not ok');
  }

  if (ctor != (condition ? .optional(1) : .named(x: 1))) {
    //                      ^^^^^^^^
    // [analyzer] unspecified
    // [cfe] No type was provided to find the dot shorthand 'optional'.
    //                                     ^^^^^
    // [analyzer] unspecified
    // [cfe] No type was provided to find the dot shorthand 'named'.
    print('not ok');
  }

  if (ctor case == (constCondition ? const .constRegular(1) : const .constNamed(x: 1))) {
    //                                      ^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] The static method or constructor 'constRegular' isn't defined for the type 'Object?'.
    //                                                               ^^^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] The static method or constructor 'constNamed' isn't defined for the type 'Object?'.
    print('not ok');
  }

  if (ctor case != (constCondition ? const .constOptional(1) : const .constRegular(1))) {
    //                                      ^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] The static method or constructor 'constOptional' isn't defined for the type 'Object?'.
    //                                                                ^^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] The static method or constructor 'constRegular' isn't defined for the type 'Object?'.
    print('not ok');
  }

  const ConstructorExt constCtorExt = .constRegular(1);
  const bool rhsCtorExtEq = constCtorExt == (constCondition ? .constRegular(1) : ConstructorExt.constNamed(x: 1));
  //                                                           ^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constRegular'.

  const bool rhsCtorExtNeq = constCtorExt != (constCondition ? ConstructorExt.constOptional(1) : .constRegular(1));
  //                                                                                              ^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] No type was provided to find the dot shorthand 'constRegular'.

  if (ctorExt == (condition ? .new(1) : .regular(1))) {
    //                         ^^^
    // [analyzer] unspecified
    // [cfe] No type was provided to find the dot shorthand 'new'.
    //                                   ^^^^^^^
    // [analyzer] unspecified
    // [cfe] No type was provided to find the dot shorthand 'regular'.
    print('not ok');
  }

  if (ctorExt != (condition ? .named(x: 1) : .optional(1))) {
    //                         ^^^^^
    // [analyzer] unspecified
    // [cfe] No type was provided to find the dot shorthand 'named'.
    //                                        ^^^^^^^^
    // [analyzer] unspecified
    // [cfe] No type was provided to find the dot shorthand 'optional'.
    print('not ok');
  }

  if (ctorExt case == (constCondition ? const .constRegular(1) : const .constNamed(x: 1))) {
    //                                         ^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] The static method or constructor 'constRegular' isn't defined for the type 'Object?'.
    //                                                                  ^^^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] The static method or constructor 'constNamed' isn't defined for the type 'Object?'.
    print('not ok');
  }

  if (ctorExt case != (constCondition ? const .constOptional(1) : const .constRegular(1))) {
    //                                         ^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] The static method or constructor 'constOptional' isn't defined for the type 'Object?'.
    //                                                                   ^^^^^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] The static method or constructor 'constRegular' isn't defined for the type 'Object?'.
    print('not ok');
  }
}

void objectContextType(ConstructorClass ctor, ConstructorExt ctorExt) {
  const ConstructorClass constCtor = .constRegular(1);
  const bool contextTypeCtorEqRegular = (constCtor as Object) == .constRegular(1);
  //                                                              ^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constRegular' isn't defined for the type 'Object'.

  const bool contextTypeCtorEqNamed = (constCtor as Object) == .constNamed(x: 1);
  //                                                            ^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constNamed' isn't defined for the type 'Object'.

  const bool contextTypeCtorEqOptional = (constCtor as Object) == .constOptional(1);
  //                                                               ^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constOptional' isn't defined for the type 'Object'.

  const bool contextTypeCtorNeqRegular = (constCtor as Object) != .constRegular(1);
  //                                                               ^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constRegular' isn't defined for the type 'Object'.

  const bool contextTypeCtorNeqNamed = (constCtor as Object) != .constNamed(x: 1);
  //                                                             ^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constNamed' isn't defined for the type 'Object'.

  const bool contextTypeCtorNeqOptional = (constCtor as Object) != .constOptional(1);
  //                                                                ^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constOptional' isn't defined for the type 'Object'.

  if ((ctor as Object) == .new(1)) print('not ok');
  //                          ^
  // [analyzer] unspecified
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.

  if ((ctor as Object) == .regular(1)) print('not ok');
  //                       ^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'regular' isn't defined for the type 'Object'.

  if ((ctor as Object) == .named(x: 1)) print('not ok');
  //                       ^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'named' isn't defined for the type 'Object'.

  if ((ctor as Object) == .optional(1)) print('not ok');
  //                       ^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'optional' isn't defined for the type 'Object'.

  if ((ctor as Object) != .new(1)) print('not ok');
  //                          ^
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.

  if ((ctor as Object) != .regular(1)) print('not ok');
  //                       ^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'regular' isn't defined for the type 'Object'.

  if ((ctor as Object) != .named(x: 1)) print('not ok');
  //                       ^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'named' isn't defined for the type 'Object'.

  if ((ctor as Object) != .optional(1)) print('not ok');
  //                       ^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'optional' isn't defined for the type 'Object'.

  if ((ctor as Object) case == const .constRegular(1)) print('not ok');
  //                                  ^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constRegular' isn't defined for the type 'Object'.

  if ((ctor as Object) case == const .constNamed(x: 1)) print('not ok');
  //                                  ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constNamed' isn't defined for the type 'Object'.

  if ((ctor as Object) case == const .constOptional(1)) print('not ok');
  //                                  ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constOptional' isn't defined for the type 'Object'.

  if ((ctor as Object) case != const .constRegular(1)) print('not ok');
  //                                  ^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constRegular' isn't defined for the type 'Object'.

  if ((ctor as Object) case != const .constNamed(x: 1)) print('not ok');
  //                                  ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constNamed' isn't defined for the type 'Object'.

  if ((ctor as Object) case != const .constOptional(1)) print('not ok');
  //                                  ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constOptional' isn't defined for the type 'Object'.

  const ConstructorExt constCtorExt = .constRegular(1);
  const bool contextTypeCtorExtEqRegular = (constCtorExt as Object) == .constRegular(1);
  //                                                                    ^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constRegular' isn't defined for the type 'Object'.

  const bool contextTypeCtorExtEqNamed = (constCtorExt as Object) == .constNamed(x: 1);
  //                                                                  ^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constNamed' isn't defined for the type 'Object'.

  const bool contextTypeCtorExtEqOptional = (constCtorExt as Object) == .constOptional(1);
  //                                                                     ^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constOptional' isn't defined for the type 'Object'.

  const bool contextTypeCtorExtNeqRegular = (constCtorExt as Object) != .constRegular(1);
  //                                                                     ^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constRegular' isn't defined for the type 'Object'.

  const bool contextTypeCtorExtNeqNamed = (constCtorExt as Object) != .constNamed(x: 1);
  //                                                                   ^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constNamed' isn't defined for the type 'Object'.

  const bool contextTypeCtorExtNeqOptional = (constCtorExt as Object) != .constOptional(1);
  //                                                                      ^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constOptional' isn't defined for the type 'Object'.

  if ((ctorExt as Object) == .new(1)) print('not ok');
  //                             ^
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.

  if ((ctorExt as Object) == .regular(1)) print('not ok');
  //                          ^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'regular' isn't defined for the type 'Object'.

  if ((ctorExt as Object) == .named(x: 1)) print('not ok');
  //                          ^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'named' isn't defined for the type 'Object'.

  if ((ctorExt as Object) == .optional(1)) print('not ok');
  //                          ^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'optional' isn't defined for the type 'Object'.

  if ((ctorExt as Object) != .new(1)) print('not ok');
  //                             ^
  // [cfe] Too many positional arguments: 0 allowed, but 1 found.

  if ((ctorExt as Object) != .regular(1)) print('not ok');
  //                          ^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'regular' isn't defined for the type 'Object'.

  if ((ctorExt as Object) != .named(x: 1)) print('not ok');
  //                          ^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'named' isn't defined for the type 'Object'.

  if ((ctorExt as Object) != .optional(1)) print('not ok');
  //                          ^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'optional' isn't defined for the type 'Object'.

  if ((ctorExt as Object) case == const .constRegular(1)) print('not ok');
  //                                     ^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constRegular' isn't defined for the type 'Object'.

  if ((ctorExt as Object) case == const .constNamed(x: 1)) print('not ok');
  //                                     ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constNamed' isn't defined for the type 'Object'.

  if ((ctorExt as Object) case == const .constOptional(1)) print('not ok');
  //                                     ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constOptional' isn't defined for the type 'Object'.

  if ((ctorExt as Object) case != const .constRegular(1)) print('not ok');
  //                                     ^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constRegular' isn't defined for the type 'Object'.

  if ((ctorExt as Object) case != const .constNamed(x: 1)) print('not ok');
  //                                     ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constNamed' isn't defined for the type 'Object'.

  if ((ctorExt as Object) case != const .constOptional(1)) print('not ok');
  //                                     ^^^^^^^^^^^^^^^^
  // [analyzer] unspecified
  // [cfe] The static method or constructor 'constOptional' isn't defined for the type 'Object'.
}

void main() {
  ConstructorClass ctor = .new(1);
  const ConstructorClass constCtor = .constRegular(1);
  ConstructorExt ctorExt = .new(1);
  const ConstructorExt constCtorExt = .constRegular(1);

  notSymmetrical(ctor, ctorExt);
  rhsNeedsToBeShorthand(ctor, ctorExt, true);
  rhsNeedsToBeShorthand(ctor, ctorExt, false);
  objectContextType(ctor, ctorExt);

  // Test the constant evaluation for dot shorthands in const constructor
  // asserts.
  const ConstConstructorAssert.regular(constCtor);
  const ConstConstructorAssert.named(constCtor);
  const ConstConstructorAssert.optional(constCtor);
  const ConstConstructorAssert.regularExt(constCtorExt);
  const ConstConstructorAssert.namedExt(constCtorExt);
  const ConstConstructorAssert.optionalExt(constCtorExt);
}
