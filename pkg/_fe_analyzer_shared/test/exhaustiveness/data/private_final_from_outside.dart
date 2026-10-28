// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class ClassBody {}

// Pretend that this is inaccessible for testing 'reduced'.
sealed class _ClassBodyImpl implements ClassBody {}

final class BlockClassBody implements ClassBody {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _BlockClassBodyImpl extends ClassBodyImpl
    implements BlockClassBody {}

final class EmptyClassBody implements ClassBody {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _EmptyClassBodyImpl extends ClassBodyImpl
    implements EmptyClassBody {}

test1(ClassBody c) => /*
 checkingOrder={ClassBody,_ClassBodyImpl,BlockClassBody,EmptyClassBody},
 error=non-exhaustive:BlockClassBody();EmptyClassBody(),
 expandedSubtypes={BlockClassBody,EmptyClassBody},
 subtypes={_ClassBodyImpl,BlockClassBody,EmptyClassBody},
 type=ClassBody
*/
    switch (c) {};

test2(BlockClassBody c) => /*
 error=non-exhaustive:BlockClassBody(),
 type=BlockClassBody
*/
    switch (c) {};

test3(EmptyClassBody c) => /*
 error=non-exhaustive:EmptyClassBody(),
 type=EmptyClassBody
*/
    switch (c) {};

test4(ClassBody c) => /*
 checkingOrder={ClassBody,_ClassBodyImpl,BlockClassBody,EmptyClassBody},
 error=non-exhaustive:BlockClassBody();EmptyClassBody(),
 expandedSubtypes={BlockClassBody,EmptyClassBody},
 subtypes={_ClassBodyImpl,BlockClassBody,EmptyClassBody},
 type=ClassBody
*/ switch (c) {
  _BlockClassBodyImpl() /*space=_BlockClassBodyImpl*/ => 0,
  _EmptyClassBodyImpl() /*space=_EmptyClassBodyImpl*/ => 1,
};

test5(ClassBody c) => /*
 checkingOrder={ClassBody,_ClassBodyImpl,BlockClassBody,EmptyClassBody},
 error=non-exhaustive:BlockClassBody();EmptyClassBody(),
 expandedSubtypes={BlockClassBody,EmptyClassBody},
 subtypes={_ClassBodyImpl,BlockClassBody,EmptyClassBody},
 type=ClassBody
*/ switch (c) {
  _ClassBodyImpl() /*space=_ClassBodyImpl*/ => 0,
};

test6(ClassBody c) => /*
 checkingOrder={ClassBody,_ClassBodyImpl,BlockClassBody,EmptyClassBody},
 expandedSubtypes={BlockClassBody,EmptyClassBody},
 subtypes={_ClassBodyImpl,BlockClassBody,EmptyClassBody},
 type=ClassBody
*/ switch (c) {
  BlockClassBody() /*space=BlockClassBody*/ => 0,
  EmptyClassBody() /*space=EmptyClassBody*/ => 1,
};
