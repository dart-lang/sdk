// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum {
  a,
  b,
  c,
  d,
  e,
}

nonExhaustiveEnum1(
        Enum
            e) => /*
             checkingOrder={Enum,Enum.a,Enum.b,Enum.c,Enum.d,Enum.e},
             error=non-exhaustive:Enum.b;Enum.c;Enum.d;Enum.e,
             subtypes={Enum.a,Enum.b,Enum.c,Enum.d,Enum.e},
             type=Enum
            */
    switch (e) {
      Enum.a /*space=Enum.a*/ => 0,
    };

nonExhaustiveEnumNested1(
        (
          Enum,
          Enum
        ) r) => /*
         error=non-exhaustive:(Enum.a, Enum.b),
         fields={$1:Enum,$2:Enum},
         type=(Enum, Enum)
        */
    switch (r) {
      (Enum.a, Enum.a) /*space=(Enum.a, Enum.a)*/ => 0,
      (Enum.c, Enum.a) /*space=(Enum.c, Enum.a)*/ => 1,
      (Enum.e, Enum a) /*space=(Enum.e, Enum)*/ => 2,
    };

nonExhaustiveEnumNested2(
        (
          Enum,
          Enum
        ) r) => /*
         error=non-exhaustive:(Enum.b, Enum.a),
         fields={$1:Enum,$2:Enum},
         type=(Enum, Enum)
        */
    switch (r) {
      (Enum.a, Enum.a) /*space=(Enum.a, Enum.a)*/ => 0,
      (Enum.a, Enum.c) /*space=(Enum.a, Enum.c)*/ => 1,
      (Enum.a, Enum e) /*space=(Enum.a, Enum)*/ => 2,
    };

nonExhaustiveEnumNested3(
        (
          Enum,
          Enum
        ) r) => /*
         error=non-exhaustive:(Enum.b, Enum.a),
         fields={$1:Enum,$2:Enum},
         type=(Enum, Enum)
        */
    switch (r) {
      (Enum.a, Enum()) /*space=(Enum.a, Enum)*/ => 0,
      (Enum.c, Enum()) /*space=(Enum.c, Enum)*/ => 1,
      (Enum.e, Enum()) /*space=(Enum.e, Enum)*/ => 2,
    };

nonExhaustiveEnumNested4(
        (
          Enum,
          Enum
        ) r) => /*
         error=non-exhaustive:(Enum.a, Enum.b),
         fields={$1:Enum,$2:Enum},
         type=(Enum, Enum)
        */
    switch (r) {
      (Enum(), Enum.a) /*space=(Enum, Enum.a)*/ => 0,
      (Enum(), Enum.c) /*space=(Enum, Enum.c)*/ => 1,
      (Enum(), Enum.e) /*space=(Enum, Enum.e)*/ => 2,
    };

sealed class S {}

class A extends S {}

class B extends S {}

class C extends S {}

class D extends S {}

class E extends S {}

nonExhaustiveSealed1(
        S s) => /*
         checkingOrder={S,A,B,C,D,E},
         error=non-exhaustive:B();C();D();E(),
         subtypes={A,B,C,D,E},
         type=S
        */
    switch (s) {
      A() /*space=A*/ => 0,
    };

nonExhaustiveSealed2(
        S s) => /*
         checkingOrder={S,A,B,C,D,E},
         error=non-exhaustive:B();D(),
         subtypes={A,B,C,D,E},
         type=S
        */
    switch (s) {
      A() /*space=A*/ => 0,
      C() /*space=C*/ => 1,
      E() /*space=E*/ => 2,
    };

nonExhaustiveSealedNested1(
        (
          S,
          S
        ) r) => /*
         error=non-exhaustive:(A(), B()),
         fields={$1:S,$2:S},
         type=(S, S)
        */
    switch (r) {
      (A(), A()) /*space=(A, A)*/ => 0,
      (C(), A()) /*space=(C, A)*/ => 1,
      (E(), A()) /*space=(E, A)*/ => 2,
    };

nonExhaustiveSealedNested2(
        (
          S,
          S
        ) r) => /*
         error=non-exhaustive:(A(), B()),
         fields={$1:S,$2:S},
         type=(S, S)
        */
    switch (r) {
      (A(), A()) /*space=(A, A)*/ => 0,
      (A(), C()) /*space=(A, C)*/ => 1,
      (A(), E()) /*space=(A, E)*/ => 2,
    };

nonExhaustiveSealedNested3(
        (
          S,
          S
        ) r) => /*
         error=non-exhaustive:(B(), A()),
         fields={$1:S,$2:S},
         type=(S, S)
        */
    switch (r) {
      (A(), S()) /*space=(A, S)*/ => 0,
      (C(), S()) /*space=(C, S)*/ => 1,
      (E(), S()) /*space=(E, S)*/ => 2,
    };

nonExhaustiveSealedNested4(
        (
          S,
          S
        ) r) => /*
         error=non-exhaustive:(A(), B()),
         fields={$1:S,$2:S},
         type=(S, S)
        */
    switch (r) {
      (S(), A()) /*space=(S, A)*/ => 0,
      (S(), C()) /*space=(S, C)*/ => 1,
      (S(), E()) /*space=(S, E)*/ => 2,
    };
