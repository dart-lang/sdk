// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands should not be able to access private classes in other
// libraries.

import 'private_class_lib.dart';

void main() {
  context(.new());
  //       ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.
  contextAlias(.new());
  //            ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  context(.new.asC);
  //      ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //       ^
  // [cfe] No type was provided to find the dot shorthand 'new'.
  contextAlias(.new.asC);
  //           ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //            ^
  // [cfe] No type was provided to find the dot shorthand 'new'.

  context(.getter);
  //      ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //       ^
  // [cfe] No type was provided to find the dot shorthand 'getter'.
  contextAlias(.getter);
  //           ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //            ^
  // [cfe] No type was provided to find the dot shorthand 'getter'.

  context(.method());
  //       ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'method'.
  contextAlias(.method());
  //            ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'method'.

  context(.named());
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'named'.
  contextAlias(.named());
  //            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'named'.

  context(Public_C()); // But this is OK.
  contextAlias(Public_C());

  contextConst(const .new());
  //           ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                  ^
  // [cfe] No type was provided to find the dot shorthand 'new'.
  contextConstAlias(const .new());
  //                ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                       ^
  // [cfe] No type was provided to find the dot shorthand 'new'.

  contextConst(const .named());
  //           ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                  ^
  // [cfe] No type was provided to find the dot shorthand 'named'.
  contextConstAlias(const .named());
  //                ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                       ^
  // [cfe] No type was provided to find the dot shorthand 'named'.

  contextConst(const Public_Const()); // But this is OK.
  contextConstAlias(const Public_Const());
}
