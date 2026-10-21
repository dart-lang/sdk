// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class S {}

abstract final class A extends S {}

abstract final class B extends S {}

// Pretend that this is inaccessible for testing 'reduced'.
sealed class _SImpl implements S {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _AImpl extends _SImpl implements A {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _BImpl extends _SImpl implements B {}

exhaustive0(S s) => /*
 checkingOrder={S,A,B,_SImpl,_AImpl,_BImpl},
 expandedSubtypes={A,B,_AImpl,_BImpl},
 subtypes={A,B,_SImpl},
 type=S
*/ switch (s) {
  _AImpl() /*space=_AImpl*/ => 0,
  _BImpl() /*space=_BImpl*/ => 1,
  _ /*space=S*/ => 2,
};

exhaustive1(S s) => /*
 checkingOrder={S,A,B,_SImpl,_AImpl,_BImpl},
 expandedSubtypes={A,B,_AImpl,_BImpl},
 subtypes={A,B,_SImpl},
 type=S
*/ switch (s) {
  A() /*space=A*/ => 0,
  B() /*space=B*/ => 1,
};

nonExhaustive0(S s) => /*
 checkingOrder={S,A,B,_SImpl,_AImpl,_BImpl},
 error=non-exhaustive:A();B(),
 expandedSubtypes={A,B,_AImpl,_BImpl},
 subtypes={A,B,_SImpl},
 type=S
*/ switch (s) {
  _AImpl() /*space=_AImpl*/ => 0,
  _BImpl() /*space=_BImpl*/ => 1,
};

nonExhaustive1(S s) => /*
 checkingOrder={S,A,B,_SImpl,_AImpl,_BImpl},
 error=non-exhaustive:A();B();_AImpl();_BImpl(),
 expandedSubtypes={A,B,_AImpl,_BImpl},
 reduced=non-exhaustive:A();B(),
 subtypes={A,B,_SImpl},
 type=S
*/
    switch (s) {};

nonExhaustive2(S s) => /*
 checkingOrder={S,A,B,_SImpl,_AImpl,_BImpl},
 error=non-exhaustive:B();_BImpl(),
 expandedSubtypes={A,B,_AImpl,_BImpl},
 reduced=non-exhaustive:B(),
 subtypes={A,B,_SImpl},
 type=S
*/ switch (s) {
  A() /*space=A*/ => 0,
};
