// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

// Import a null-safe library which defines several classes `B...`, each of
// which implements either `A<int>` or `A<int?>`, or in the case of `Bwm` and
// `Bwmq` which implement either `M<int>` or `M<int?>`, respectively. This
// library then declares legacy classes that create a superinterface conflict,
// e.g., by having both `A<int>` and `A<int?>` as indirect superinterfaces.
// The absence of errors in this test verifies that member signature
// compatibility in legacy libraries is done with respect to the nullability
// erased signatures.

import 'legacy_resolves_conflict_1_lib.dart';

// Naming conventions: This library iterates over all the ways a legacy class
// can have conflicting opted-in classes `B...` as superinterfaces. The ones
// that can be concrete are concrete. The resulting classes are simply named
// `C#` where `#` is a running counter (it doesn't seem helpful to encode the
// way in which each of them has said superinterfaces).

class C0 extends Be implements Beq {}

abstract class C1 implements Be, Beq {}

class C2 extends Be implements Biq {}

abstract class C3 implements Be, Biq {}

class C4 extends Be implements Bwcq {}

abstract class C5 implements Be, Bwcq {}

class C6 extends Be implements Bwmq {}

abstract class C7 implements Be, Bwmq {}

class C8 extends Bi implements Beq {}

abstract class C9 implements Bi, Beq {}

class C10 extends Bi implements Biq {}

abstract class C11 implements Bi, Biq {}

class C12 extends Bi implements Bwcq {}

abstract class C13 implements Bi, Bwcq {}

class C14 extends Bi implements Bwmq {}

abstract class C15 implements Bi, Bwmq {}

class C16 extends Bwc implements Beq {}

abstract class C17 implements Bwc, Beq {}

class C18 extends Bwc implements Biq {}

abstract class C19 implements Bwc, Biq {}

class C20 extends Bwc implements Bwcq {}

abstract class C21 implements Bwc, Bwcq {}

class C22 extends Bwc implements Bwmq {}

abstract class C23 implements Bwc, Bwmq {}

class C24 extends Bwm implements Beq {}

abstract class C25 implements Bwm, Beq {}

class C26 extends Bwm implements Biq {}

abstract class C27 implements Bwm, Biq {}

class C28 extends Bwm implements Bwcq {}

abstract class C29 implements Bwm, Bwcq {}

class C30 extends Bwm implements Bwmq {}

abstract class C31 implements Bwm, Bwmq {}

class C32 extends Beq implements Be {}

abstract class C33 implements Beq, Be {}

class C34 extends Beq implements Bi {}

abstract class C35 implements Beq, Bi {}

class C36 extends Beq implements Bwc {}

abstract class C37 implements Beq, Bwc {}

class C38 extends Beq implements Bwm {}

abstract class C39 implements Beq, Bwm {}

class C40 extends Biq implements Be {}

abstract class C41 implements Biq, Be {}

class C42 extends Biq implements Bi {}

abstract class C43 implements Biq, Bi {}

class C44 extends Biq implements Bwc {}

abstract class C45 implements Biq, Bwc {}

class C46 extends Biq implements Bwm {}

abstract class C47 implements Biq, Bwm {}

class C48 extends Bwcq implements Be {}

abstract class C49 implements Bwcq, Be {}

class C50 extends Bwcq implements Bi {}

abstract class C51 implements Bwcq, Bi {}

class C52 extends Bwcq implements Bwc {}

abstract class C53 implements Bwcq, Bwc {}

class C54 extends Bwcq implements Bwm {}

abstract class C55 implements Bwcq, Bwm {}

class C56 extends Bwmq implements Be {}

abstract class C57 implements Bwmq, Be {}

class C58 extends Bwmq implements Bi {}

abstract class C59 implements Bwmq, Bi {}

class C60 extends Bwmq implements Bwc {}

abstract class C61 implements Bwmq, Bwc {}

class C62 extends Bwmq implements Bwm {}

abstract class C63 implements Bwmq, Bwm {}
