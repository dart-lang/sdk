// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dot shorthands should not be able to access private extension types in other
// libraries.

// SharedOptions=--enable-experiment=dot-shorthands

import 'private_extension_type_lib.dart';

void main() {
  context(.new(0));
  //       ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.
  contextAlias(.new(0));
  //            ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'new'.

  context(.new.asE);
  //      ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //       ^
  // [cfe] No type was provided to find the dot shorthand 'new'.
  contextAlias(.new.asE);
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

  context(.named(0));
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'named'.
  contextAlias(.named(0));
  //            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] No type was provided to find the dot shorthand 'named'.

  context(Public_E(0)); // But this is OK.
  contextAlias(Public_E(0));

  contextConst(const .new(0));
  //           ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                  ^
  // [cfe] No type was provided to find the dot shorthand 'new'.
  contextConstAlias(const .new(0));
  //                ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                       ^
  // [cfe] No type was provided to find the dot shorthand 'new'.

  contextConst(const .named(0));
  //           ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                  ^
  // [cfe] No type was provided to find the dot shorthand 'named'.
  contextConstAlias(const .named(0));
  //                ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                       ^
  // [cfe] No type was provided to find the dot shorthand 'named'.

  contextConst(const Public_ConstE(0)); // But this is OK.
  contextConstAlias(const Public_ConstE(0));
}
