// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1 { a }

exhaustive1(E1 e) => /*
 checkingOrder={E1,E1.a},
 subtypes={E1.a},
 type=E1
*/ switch (e) {
  E1.a /*space=E1.a*/ => 0,
};

nonExhaustive1_1(E1 e) => /*
 checkingOrder={E1,E1.a},
 error=non-exhaustive:E1.a,
 subtypes={E1.a},
 type=E1
*/
    switch (e) {};

enum E2 { a, b }

exhaustive2(E2 e) => /*
 checkingOrder={E2,E2.a,E2.b},
 subtypes={E2.a,E2.b},
 type=E2
*/ switch (e) {
  E2.a /*space=E2.a*/ => 0,
  E2.b /*space=E2.b*/ => 1,
};

nonExhaustive2_1(E2 e) => /*
 checkingOrder={E2,E2.a,E2.b},
 error=non-exhaustive:E2.b,
 subtypes={E2.a,E2.b},
 type=E2
*/ switch (e) {
  E2.a /*space=E2.a*/ => 0,
};

nonExhaustive2_2(E2 e) => /*
 checkingOrder={E2,E2.a,E2.b},
 error=non-exhaustive:E2.a;E2.b,
 subtypes={E2.a,E2.b},
 type=E2
*/
    switch (e) {};

enum E3 { a, b, c }

exhaustive3(E3 e) => /*
 checkingOrder={E3,E3.a,E3.b,E3.c},
 subtypes={E3.a,E3.b,E3.c},
 type=E3
*/ switch (e) {
  E3.a /*space=E3.a*/ => 0,
  E3.b /*space=E3.b*/ => 1,
  E3.c /*space=E3.c*/ => 2,
};

nonExhaustive3_1(E3 e) => /*
 checkingOrder={E3,E3.a,E3.b,E3.c},
 error=non-exhaustive:E3.c,
 subtypes={E3.a,E3.b,E3.c},
 type=E3
*/ switch (e) {
  E3.a /*space=E3.a*/ => 0,
  E3.b /*space=E3.b*/ => 1,
};

nonExhaustive3_2(E3 e) => /*
 checkingOrder={E3,E3.a,E3.b,E3.c},
 error=non-exhaustive:E3.b;E3.c,
 subtypes={E3.a,E3.b,E3.c},
 type=E3
*/ switch (e) {
  E3.a /*space=E3.a*/ => 0,
};

nonExhaustive3_3(E3 e) => /*
 checkingOrder={E3,E3.a,E3.b,E3.c},
 error=non-exhaustive:E3.a;E3.b;E3.c,
 subtypes={E3.a,E3.b,E3.c},
 type=E3
*/
    switch (e) {};

enum E4 { a, b, c, d }

exhaustive4(E4 e) => /*
 checkingOrder={E4,E4.a,E4.b,E4.c,E4.d},
 subtypes={E4.a,E4.b,E4.c,E4.d},
 type=E4
*/ switch (e) {
  E4.a /*space=E4.a*/ => 0,
  E4.b /*space=E4.b*/ => 1,
  E4.c /*space=E4.c*/ => 2,
  E4.d /*space=E4.d*/ => 3,
};

nonExhaustive4_1(E4 e) => /*
 checkingOrder={E4,E4.a,E4.b,E4.c,E4.d},
 error=non-exhaustive:E4.c;E4.d,
 subtypes={E4.a,E4.b,E4.c,E4.d},
 type=E4
*/ switch (e) {
  E4.a /*space=E4.a*/ => 0,
  E4.b /*space=E4.b*/ => 1,
};

nonExhaustive4_2(E4 e) => /*
 checkingOrder={E4,E4.a,E4.b,E4.c,E4.d},
 error=non-exhaustive:E4.b;E4.c;E4.d,
 subtypes={E4.a,E4.b,E4.c,E4.d},
 type=E4
*/ switch (e) {
  E4.a /*space=E4.a*/ => 0,
};

nonExhaustive4_3(E4 e) => /*
 checkingOrder={E4,E4.a,E4.b,E4.c,E4.d},
 error=non-exhaustive:E4.a;E4.b;E4.c;E4.d,
 subtypes={E4.a,E4.b,E4.c,E4.d},
 type=E4
*/
    switch (e) {};
