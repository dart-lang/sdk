// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// An empty declaration body, `{}`, can be replaced by `;`.

// SharedOptions=--enable-experiment=primary-constructors

class S1;
class S2 extends S;
class S3 with M;
class S4 extends S with M;
class S5 extends S with M, N;
class S6 implements I;
class S7 extends S implements I;
class S8 with M implements I;
class S9 extends S with M implements I;
class S10 extends S with M, N implements I;
class S11 implements I, J;
class S12 extends S implements I, J;
class S13 with M implements I, J;
class S14 extends S with M implements I, J;
class S15 extends S with M, N implements I, J;

class const P1();
class const P2() extends S;
class const P3() with M;
class const P4() extends S with M;
class const P5() extends S with M, N;
class const P6() implements I;
class const P7() extends S implements I;
class const P8() with M implements I;
class const P9() extends S with M implements I;
class const P10() extends S with M, N implements I;
class const P11() implements I, J;
class const P12() extends S implements I, J;
class const P13() with M implements I, J;
class const P14() extends S with M implements I, J;
class const P15() extends S with M, N implements I, J;

class MC1 = S with M;
class MC2 = S with M, N;
class MC3 = S with M implements I;
class MC4 = S with M, N implements I;

mixin M1;
mixin M2 on S;
mixin M3 on S, M;
mixin M4 implements I;
mixin M5 on S implements I;
mixin M6 on S, M implements I;
mixin M7 implements I, J;
mixin M8 on S implements I, J;
mixin M9 on S, M implements I, J;

extension type X1(I _);
extension type X2(I _) implements I;
extension type X3(IJ _) implements I, J;
extension type const X4(final I _);
extension type const X5(final I _) implements I;
extension type const X6(final IJ _) implements I, J;

extension on I;
extension Ex1 on I;
extension Ex2<T> on T;

// Helpers.
interface class I {}
interface class J {}
interface class IJ implements I, J {}
class S {
  const S();
}
mixin M {}
mixin N {}

class M1With with M1;
class M2With extends S with M2;
class M3With extends S with M, M3;
class M4With with M4;
class M5With extends S with M5;
class M6With extends S with M, M6;
class M7With with M7;
class M8With extends S with M8;
class M9With extends S with M, M9;

void main() {
  S1();
  S2();
  S3();
  S4();
  S5();
  S6();
  S7();
  S8();
  S9();
  S10();
  S11();
  S12();
  S13();
  S14();
  S15();

  P1();
  P2();
  P3();
  P4();
  P5();
  P6();
  P7();
  P8();
  P9();
  P10();
  P11();
  P12();
  P13();
  P14();
  P15();

  MC1();
  MC2();
  MC3();
  MC4();

  X1(I());
  X2(I());
  X3(IJ());
  X4(I());
  X5(I());
  X6(IJ());

  M1With();
  M2With();
  M3With();
  M4With();
  M5With();
  M6With();
  M7With();
  M8With();
  M9With();
}
