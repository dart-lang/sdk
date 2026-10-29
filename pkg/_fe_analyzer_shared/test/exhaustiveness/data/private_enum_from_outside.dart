// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1 {
  // Pretend that this is inaccessible for testing 'reduced'.
  _a,
}

nonExhaustive1_1(E1 e) => /*
 checkingOrder={E1,E1._a},
 error=non-exhaustive:E1._a,
 reduced=non-exhaustive:needsDefault,
 subtypes={E1._a},
 type=E1
*/
    switch (e) {};

enum E2 {
  a,
  // Pretend that this is inaccessible for testing 'reduced'.
  _b,
}

nonExhaustive2_1(E2 e) => /*
 checkingOrder={E2,E2.a,E2._b},
 error=non-exhaustive:E2._b,
 reduced=non-exhaustive:needsDefault,
 subtypes={E2.a,E2._b},
 type=E2
*/ switch (e) {
  E2.a /*space=E2.a*/ => 0,
};

nonExhaustive2_2(E2 e) => /*
 checkingOrder={E2,E2.a,E2._b},
 error=non-exhaustive:E2.a;E2._b,
 reduced=non-exhaustive:E2.a;needsDefault,
 subtypes={E2.a,E2._b},
 type=E2
*/
    switch (e) {};

enum E3 {
  a,
  b,
  // Pretend that this is inaccessible for testing 'reduced'.
  _c,
}

nonExhaustive3_1(E3 e) => /*
 checkingOrder={E3,E3.a,E3.b,E3._c},
 error=non-exhaustive:E3._c,
 reduced=non-exhaustive:needsDefault,
 subtypes={E3.a,E3.b,E3._c},
 type=E3
*/ switch (e) {
  E3.a /*space=E3.a*/ => 0,
  E3.b /*space=E3.b*/ => 1,
};

nonExhaustive3_2(E3 e) => /*
 checkingOrder={E3,E3.a,E3.b,E3._c},
 error=non-exhaustive:E3.b;E3._c,
 reduced=non-exhaustive:E3.b;needsDefault,
 subtypes={E3.a,E3.b,E3._c},
 type=E3
*/ switch (e) {
  E3.a /*space=E3.a*/ => 0,
};

nonExhaustive3_3(E3 e) => /*
 checkingOrder={E3,E3.a,E3.b,E3._c},
 error=non-exhaustive:E3.a;E3.b;E3._c,
 reduced=non-exhaustive:E3.a;E3.b;needsDefault,
 subtypes={E3.a,E3.b,E3._c},
 type=E3
*/
    switch (e) {};

enum E4 {
  a,
  b,
  // Pretend that this is inaccessible for testing 'reduced'.
  _c,
  _d,
}

nonExhaustive4_1(E4 e) => /*
 checkingOrder={E4,E4.a,E4.b,E4._c,E4._d},
 error=non-exhaustive:E4._c;E4._d,
 reduced=non-exhaustive:needsDefault,
 subtypes={E4.a,E4.b,E4._c,E4._d},
 type=E4
*/ switch (e) {
  E4.a /*space=E4.a*/ => 0,
  E4.b /*space=E4.b*/ => 1,
};

nonExhaustive4_2(E4 e) => /*
 checkingOrder={E4,E4.a,E4.b,E4._c,E4._d},
 error=non-exhaustive:E4.b;E4._c;E4._d,
 reduced=non-exhaustive:E4.b;needsDefault,
 subtypes={E4.a,E4.b,E4._c,E4._d},
 type=E4
*/ switch (e) {
  E4.a /*space=E4.a*/ => 0,
};

nonExhaustive4_3(E4 e) => /*
 checkingOrder={E4,E4.a,E4.b,E4._c,E4._d},
 error=non-exhaustive:E4.a;E4.b;E4._c;E4._d,
 reduced=non-exhaustive:E4.a;E4.b;needsDefault,
 subtypes={E4.a,E4.b,E4._c,E4._d},
 type=E4
*/
    switch (e) {};
