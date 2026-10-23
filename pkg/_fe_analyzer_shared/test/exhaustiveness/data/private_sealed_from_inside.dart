// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class S1;
class A1 extends S1;

exhaustive1(S1 s) => /*
 checkingOrder={S1,A1},
 subtypes={A1},
 type=S1
*/ switch (s) {
  A1() /*space=A1*/ => 0,
};

nonExhaustive1_1(S1 s) => /*
 checkingOrder={S1,A1},
 error=non-exhaustive:A1(),
 subtypes={A1},
 type=S1
*/
    switch (s) {};

sealed class S2;
class A2 extends S2;
class B2 extends S2;

exhaustive2(S2 s) => /*
 checkingOrder={S2,A2,B2},
 subtypes={A2,B2},
 type=S2
*/ switch (s) {
  A2() /*space=A2*/ => 0,
  B2() /*space=B2*/ => 1,
};

nonExhaustive2_1(S2 s) => /*
 checkingOrder={S2,A2,B2},
 error=non-exhaustive:B2(),
 subtypes={A2,B2},
 type=S2
*/ switch (s) {
  A2() /*space=A2*/ => 0,
};

nonExhaustive2_2(S2 s) => /*
 checkingOrder={S2,A2,B2},
 error=non-exhaustive:A2();B2(),
 subtypes={A2,B2},
 type=S2
*/
    switch (s) {};

sealed class S3;
class A3 extends S3;
class B3 extends S3;
class C3 extends S3;

exhaustive3(S3 s) => /*
 checkingOrder={S3,A3,B3,C3},
 subtypes={A3,B3,C3},
 type=S3
*/ switch (s) {
  A3() /*space=A3*/ => 0,
  B3() /*space=B3*/ => 1,
  C3() /*space=C3*/ => 2,
};

nonExhaustive3_1(S3 s) => /*
 checkingOrder={S3,A3,B3,C3},
 error=non-exhaustive:C3(),
 subtypes={A3,B3,C3},
 type=S3
*/ switch (s) {
  A3() /*space=A3*/ => 0,
  B3() /*space=B3*/ => 1,
};

nonExhaustive3_2(S3 s) => /*
 checkingOrder={S3,A3,B3,C3},
 error=non-exhaustive:B3();C3(),
 subtypes={A3,B3,C3},
 type=S3
*/ switch (s) {
  A3() /*space=A3*/ => 0,
};

nonExhaustive3_3(S3 s) => /*
 checkingOrder={S3,A3,B3,C3},
 error=non-exhaustive:A3();B3();C3(),
 subtypes={A3,B3,C3},
 type=S3
*/
    switch (s) {};

sealed class S4;
class A4 extends S4;
class B4 extends S4;
class C4 extends S4;
class D4 extends S4;

exhaustive4(S4 s) => /*
 checkingOrder={S4,A4,B4,C4,D4},
 subtypes={A4,B4,C4,D4},
 type=S4
*/ switch (s) {
  A4() /*space=A4*/ => 0,
  B4() /*space=B4*/ => 1,
  C4() /*space=C4*/ => 2,
  D4() /*space=D4*/ => 3,
};

nonExhaustive4_1(S4 s) => /*
 checkingOrder={S4,A4,B4,C4,D4},
 error=non-exhaustive:C4();D4(),
 subtypes={A4,B4,C4,D4},
 type=S4
*/ switch (s) {
  A4() /*space=A4*/ => 0,
  B4() /*space=B4*/ => 1,
};

nonExhaustive4_2(S4 s) => /*
 checkingOrder={S4,A4,B4,C4,D4},
 error=non-exhaustive:B4();C4();D4(),
 subtypes={A4,B4,C4,D4},
 type=S4
*/ switch (s) {
  A4() /*space=A4*/ => 0,
};

nonExhaustive4_3(S4 s) => /*
 checkingOrder={S4,A4,B4,C4,D4},
 error=non-exhaustive:A4();B4();C4();D4(),
 subtypes={A4,B4,C4,D4},
 type=S4
*/
    switch (s) {};
