// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class ClassBody {}

// Pretend that this is inaccessible for testing 'reduced'.
sealed class _ClassBodyImpl implements ClassBody {}

sealed class BlockClassBody implements ClassBody {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _BlockClassBodyImpl extends _ClassBodyImpl
    implements BlockClassBody {}

sealed class EmptyClassBody implements ClassBody {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _EmptyClassBodyImpl extends _ClassBodyImpl
    implements EmptyClassBody {}

test1(ClassBody c) => /*
 checkingOrder={ClassBody,_ClassBodyImpl,BlockClassBody,EmptyClassBody,_BlockClassBodyImpl,_EmptyClassBodyImpl,_BlockClassBodyImpl,_EmptyClassBodyImpl},
 error=non-exhaustive:_BlockClassBodyImpl();_EmptyClassBodyImpl();_BlockClassBodyImpl();_EmptyClassBodyImpl(),
 expandedSubtypes={_BlockClassBodyImpl,_EmptyClassBodyImpl,_BlockClassBodyImpl,_EmptyClassBodyImpl},
 reduced=non-exhaustive:BlockClassBody();EmptyClassBody(),
 subtypes={_ClassBodyImpl,BlockClassBody,EmptyClassBody},
 type=ClassBody
*/
    switch (c) {};

test2(BlockClassBody c) => /*
 checkingOrder={BlockClassBody,_BlockClassBodyImpl},
 error=non-exhaustive:_BlockClassBodyImpl(),
 reduced=non-exhaustive:needsDefault,
 subtypes={_BlockClassBodyImpl},
 type=BlockClassBody
*/
    switch (c) {};

test3(EmptyClassBody c) => /*
 checkingOrder={EmptyClassBody,_EmptyClassBodyImpl},
 error=non-exhaustive:_EmptyClassBodyImpl(),
 reduced=non-exhaustive:needsDefault,
 subtypes={_EmptyClassBodyImpl},
 type=EmptyClassBody
*/
    switch (c) {};

test4(ClassBody c) => /*
 checkingOrder={ClassBody,_ClassBodyImpl,BlockClassBody,EmptyClassBody,_BlockClassBodyImpl,_EmptyClassBodyImpl,_BlockClassBodyImpl,_EmptyClassBodyImpl},
 expandedSubtypes={_BlockClassBodyImpl,_EmptyClassBodyImpl,_BlockClassBodyImpl,_EmptyClassBodyImpl},
 subtypes={_ClassBodyImpl,BlockClassBody,EmptyClassBody},
 type=ClassBody
*/ switch (c) {
  _BlockClassBodyImpl() /*space=_BlockClassBodyImpl*/ => 0,
  _EmptyClassBodyImpl() /*space=_EmptyClassBodyImpl*/ => 1,
};

test5(ClassBody c) => /*
 checkingOrder={ClassBody,_ClassBodyImpl,BlockClassBody,EmptyClassBody,_BlockClassBodyImpl,_EmptyClassBodyImpl,_BlockClassBodyImpl,_EmptyClassBodyImpl},
 expandedSubtypes={_BlockClassBodyImpl,_EmptyClassBodyImpl,_BlockClassBodyImpl,_EmptyClassBodyImpl},
 subtypes={_ClassBodyImpl,BlockClassBody,EmptyClassBody},
 type=ClassBody
*/ switch (c) {
  _ClassBodyImpl() /*space=_ClassBodyImpl*/ => 0,
};

test6(ClassBody c) => /*
 checkingOrder={ClassBody,_ClassBodyImpl,BlockClassBody,EmptyClassBody,_BlockClassBodyImpl,_EmptyClassBodyImpl,_BlockClassBodyImpl,_EmptyClassBodyImpl},
 expandedSubtypes={_BlockClassBodyImpl,_EmptyClassBodyImpl,_BlockClassBodyImpl,_EmptyClassBodyImpl},
 subtypes={_ClassBodyImpl,BlockClassBody,EmptyClassBody},
 type=ClassBody
*/ switch (c) {
  BlockClassBody() /*space=BlockClassBody*/ => 0,
  EmptyClassBody() /*space=EmptyClassBody*/ => 1,
};
