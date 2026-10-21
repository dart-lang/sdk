// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A {}

sealed class B implements A {}

abstract final class C implements B {}

// Pretend that this is inaccessible for testing 'reduced'.
final class _BImpl extends B {}

exhaustive0((A, A) a) => /*
 fields={$1:A,$2:A},
 type=(A, A)
*/ switch (a) {
  (C(), C()) /*space=(C, C)*/ => 0,
  (C(), _BImpl()) /*space=(C, _BImpl)*/ => 1,
  (_BImpl(), C()) /*space=(_BImpl, C)*/ => 2,
  (_BImpl(), _BImpl()) /*space=(_BImpl, _BImpl)*/ => 3,
};

exhaustive1((A, A) a) => /*
 fields={$1:A,$2:A},
 type=(A, A)
*/ switch (a) {
  (C(), C()) /*space=(C, C)*/ => 0,
  (B(), B()) /*space=(B, B)*/ => 1,
};

exhaustive2((A, A) a) => /*
 fields={$1:A,$2:A},
 type=(A, A)
*/ switch (a) {
  (B(), B()) /*space=(B, B)*/ => 0,
};

nonExhaustive0((A, A) a) => /*
 error=non-exhaustive:(C(), _BImpl()),
 fields={$1:A,$2:A},
 reduced=non-exhaustive:(C(), B()),
 type=(A, A)
*/ switch (a) {
  (C(), C()) /*space=(C, C)*/ => 0,
};

nonExhaustive1((A, A) a) => /*
 error=non-exhaustive:(_BImpl(), _),
 fields={$1:A,$2:A},
 reduced=non-exhaustive:(B(), _),
 type=(A, A)
*/ switch (a) {
  (C(), C()) /*space=(C, C)*/ => 0,
  (C(), B()) /*space=(C, B)*/ => 0,
};

exhaustive3((A, A) a) => /*
 fields={$1:A,$2:A},
 type=(A, A)
*/ switch (a) {
  (C(), C()) /*space=(C, C)*/ => 0,
  (C(), B()) /*space=(C, B)*/ => 0,
  (B(), _) /*space=(B, A)*/ => 0,
};

nonExhaustive2((A, A) a) => /*
 error=non-exhaustive:(_, _),
 type=(A, A)
*/
    switch (a) {};
