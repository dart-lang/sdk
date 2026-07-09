// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Errors involving dot shorthands of constructors.

import '../dot_shorthand_helper.dart';

void main() {
  // Using a constructor shorthand without any context.

  var ctorNew = .new();
  //             ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  const ctorConstNew = .new();
  //                   ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  var ctorNamed = .regular();
  //               ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'regular'.

  const ctorConstNamed = .regular();
  //                     ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                      ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'regular'.

  UnnamedConstructor Function() ctorTearoff = .new;
  //                                          ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                           ^
  // [cfe] The static getter or field 'new' isn't defined for the type 'UnnamedConstructor Function()'.

  Function abstractInstantiation = .new();
  //                               ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INSTANTIATE_ABSTRACT_CLASS
  //                                ^
  // [cfe] The class 'Function' is abstract and can't be instantiated.

  Function abstractClassTearoff = .new;
  //                              ^^^^
  // [analyzer] COMPILE_TIME_ERROR.TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS
  //                               ^
  // [cfe] Constructors on abstract classes can't be torn off.
}
