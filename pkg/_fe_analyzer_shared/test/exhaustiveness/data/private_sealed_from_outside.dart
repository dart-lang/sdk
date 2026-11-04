// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class S1;
// Pretend that this is inaccessible for testing 'reduced'.
class _A1 extends S1;

nonExhaustive1_1(S1 s) => /*
 checkingOrder={S1,_A1},
 error=non-exhaustive:_A1(),
 reduced=non-exhaustive:needsDefault,
 subtypes={_A1},
 type=S1
*/
    switch (s) {};

sealed class S2;
class A2 extends S2;
// Pretend that this is inaccessible for testing 'reduced'.
class _B2 extends S2;

nonExhaustive2_1(S2 s) => /*
 checkingOrder={S2,A2,_B2},
 error=non-exhaustive:_B2(),
 reduced=non-exhaustive:needsDefault,
 subtypes={A2,_B2},
 type=S2
*/ switch (s) {
  A2() /*space=A2*/ => 0,
};

nonExhaustive2_2(S2 s) => /*
 checkingOrder={S2,A2,_B2},
 error=non-exhaustive:A2();_B2(),
 reduced=non-exhaustive:A2();needsDefault,
 subtypes={A2,_B2},
 type=S2
*/
    switch (s) {};

sealed class S3;
class A3 extends S3;
class B3 extends S3;
// Pretend that this is inaccessible for testing 'reduced'.
class _C3 extends S3;

nonExhaustive3_1(S3 s) => /*
 checkingOrder={S3,A3,B3,_C3},
 error=non-exhaustive:_C3(),
 reduced=non-exhaustive:needsDefault,
 subtypes={A3,B3,_C3},
 type=S3
*/ switch (s) {
  A3() /*space=A3*/ => 0,
  B3() /*space=B3*/ => 1,
};

nonExhaustive3_2(S3 s) => /*
 checkingOrder={S3,A3,B3,_C3},
 error=non-exhaustive:B3();_C3(),
 reduced=non-exhaustive:B3();needsDefault,
 subtypes={A3,B3,_C3},
 type=S3
*/ switch (s) {
  A3() /*space=A3*/ => 0,
};

nonExhaustive3_3(S3 s) => /*
 checkingOrder={S3,A3,B3,_C3},
 error=non-exhaustive:A3();B3();_C3(),
 reduced=non-exhaustive:A3();B3();needsDefault,
 subtypes={A3,B3,_C3},
 type=S3
*/
    switch (s) {};

sealed class S4;
class A4 extends S4;
class B4 extends S4;
// Pretend that this is inaccessible for testing 'reduced'.
class _C4 extends S4;
// Pretend that this is inaccessible for testing 'reduced'.
class _D4 extends S4;

nonExhaustive4_1(S4 s) => /*
 checkingOrder={S4,A4,B4,_C4,_D4},
 error=non-exhaustive:_C4();_D4(),
 reduced=non-exhaustive:needsDefault,
 subtypes={A4,B4,_C4,_D4},
 type=S4
*/ switch (s) {
  A4() /*space=A4*/ => 0,
  B4() /*space=B4*/ => 1,
};

nonExhaustive4_2(S4 s) => /*
 checkingOrder={S4,A4,B4,_C4,_D4},
 error=non-exhaustive:B4();_C4();_D4(),
 reduced=non-exhaustive:B4();needsDefault,
 subtypes={A4,B4,_C4,_D4},
 type=S4
*/ switch (s) {
  A4() /*space=A4*/ => 0,
};

nonExhaustive4_3(S4 s) => /*
 checkingOrder={S4,A4,B4,_C4,_D4},
 error=non-exhaustive:A4();B4();_C4();_D4(),
 reduced=non-exhaustive:A4();B4();needsDefault,
 subtypes={A4,B4,_C4,_D4},
 type=S4
*/
    switch (s) {};
