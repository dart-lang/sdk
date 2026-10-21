// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class ClassBody {}

// Pretend that this is accessible for testing 'reduced'.
sealed class ClassBodyImpl implements ClassBody {}

final class BlockClassBody implements ClassBody {}

// Pretend that this is accessible for testing 'reduced'.
final class BlockClassBodyImpl extends ClassBodyImpl
    implements BlockClassBody {}

final class EmptyClassBody implements ClassBody {}

// Pretend that this is accessible for testing 'reduced'.
final class EmptyClassBodyImpl extends ClassBodyImpl
    implements EmptyClassBody {}

test1(ClassBody c) => /*
 checkingOrder={ClassBody,ClassBodyImpl,BlockClassBody,EmptyClassBody,BlockClassBodyImpl,EmptyClassBodyImpl},
 error=non-exhaustive:BlockClassBody();EmptyClassBody();BlockClassBodyImpl();EmptyClassBodyImpl(),
 expandedSubtypes={BlockClassBodyImpl,EmptyClassBodyImpl,BlockClassBody,EmptyClassBody},
 subtypes={ClassBodyImpl,BlockClassBody,EmptyClassBody},
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
 checkingOrder={ClassBody,ClassBodyImpl,BlockClassBody,EmptyClassBody,BlockClassBodyImpl,EmptyClassBodyImpl},
 error=non-exhaustive:BlockClassBody();EmptyClassBody(),
 expandedSubtypes={BlockClassBodyImpl,EmptyClassBodyImpl,BlockClassBody,EmptyClassBody},
 subtypes={ClassBodyImpl,BlockClassBody,EmptyClassBody},
 type=ClassBody
*/ switch (c) {
  BlockClassBodyImpl() /*space=BlockClassBodyImpl*/ => 0,
  EmptyClassBodyImpl() /*space=EmptyClassBodyImpl*/ => 1,
};

test5(ClassBody c) => /*
 checkingOrder={ClassBody,ClassBodyImpl,BlockClassBody,EmptyClassBody,BlockClassBodyImpl,EmptyClassBodyImpl},
 error=non-exhaustive:BlockClassBody();EmptyClassBody(),
 expandedSubtypes={BlockClassBodyImpl,EmptyClassBodyImpl,BlockClassBody,EmptyClassBody},
 subtypes={ClassBodyImpl,BlockClassBody,EmptyClassBody},
 type=ClassBody
*/ switch (c) {
  ClassBodyImpl() /*space=ClassBodyImpl*/ => 0,
};

test6(ClassBody c) => /*
 checkingOrder={ClassBody,ClassBodyImpl,BlockClassBody,EmptyClassBody,BlockClassBodyImpl,EmptyClassBodyImpl},
 expandedSubtypes={BlockClassBodyImpl,EmptyClassBodyImpl,BlockClassBody,EmptyClassBody},
 subtypes={ClassBodyImpl,BlockClassBody,EmptyClassBody},
 type=ClassBody
*/ switch (c) {
  BlockClassBody() /*space=BlockClassBody*/ => 0,
  EmptyClassBody() /*space=EmptyClassBody*/ => 1,
};
