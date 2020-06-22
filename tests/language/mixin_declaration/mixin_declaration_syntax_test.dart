// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test various combinations of valid mixin declarations.

// Class unrelated to everything else here, just Object with a toString.
class O {
  String toString() => "O";
}

abstract class A {
  String toString() => "A";
  String methodA() => "A:${this}.A";
}

class B implements A {
  String toString() => "B";
  String methodA() => "B:${this}.A";
  String methodB() => "B:${this}.B";
}

class C extends A {
  String toString() => "C";
  String methodA() => "C:${this}.A->${super.methodA()}";
  String methodC() => "C:${this}.C";
}

class AIJ implements A, I, J {
  String toString() => "AIJ";
  String methodA() => "AIJ:${this}.A";
  String methodI() => "AIJ:${this}.I";
  String methodJ() => "AIJ:${this}.J";
}

class BC extends C implements B {
  String toString() => "BC";
  String methodA() => "BC:${this}.A->${super.methodA()}";
  String methodB() => "BC:${this}.B";
  String methodC() => "BC:${this}.C->${super.methodC()}";
}

// Interfaces.
abstract class I {
  String methodI();
}
abstract class J {
  String methodJ();
}

// Simple mixin with no super-invocations, no super restrictions
// and no interfaces implemented.
mixin M {
  String toString() => "?&M";
  String methodM() => "M:${this}.M";
}


// Mixin which uses the implicit "on Object" to do a super-invocation.
mixin MO {
  String toString() => "${super.toString()}&MO";
  String methodMO() => "MO:${this}.MO";
}


// Mixin with "implements" clause.
mixin MOiIJ implements I, J {
  String toString() => "${super.toString()}&MOiIJ";
  String methodMOiIJ() => "MOiIJ:${this}.MOiIJ";
  String methodI() => "MOiIJ:${this}.I";
  String methodJ() => "MOiIJ:${this}.J";
}


// Mixin with single non-Object super-constraint.
mixin MA on A {
  String toString() => "${super.toString()}&MA";
  String methodMA() => "MA:${this}.MA";
  String methodA() => "MA:${this}.A->${super.methodA()}";
}


// Mixin with super-restriction implementing other interfaces.
mixin MAiBC on A implements B, C {
  String toString() => "${super.toString()}&MAiBC";
  String methodMAiBC() => "MAiBC:${this}.MAiBC";
  String methodA() => "MAiBC:${this}.A->${super.methodA()}";
  String methodB() => "MAiBC:${this}.B";
  String methodC() => "MAiBC:${this}.C";
}

// Mixin with "implements" clause.
mixin MBiIJ on B implements I, J {
  String toString() => "${super.toString()}&MBiIJ";
  String methodMOiIJ() => "MBiIJ:${this}.MBiIJ";
  String methodI() => "MBiIJ:${this}.I";
  String methodJ() => "MBiIJ:${this}.J";
}


// Mixin on more than one class.
mixin MBC on B, C {
  String toString() => "${super.toString()}&MBC";
  String methodMBC() => "MBC:${this}.MBC";
  String methodA() => "MBC:${this}.A->${super.methodA()}";
  String methodB() => "MBC:${this}.B->${super.methodB()}";
  String methodC() => "MBC:${this}.C->${super.methodC()}";
}


// One with everything.
mixin MBCiIJ on B, C implements I, J {
  String toString() => "${super.toString()}&MBCiIJ";
  String methodMBCiIJ() => "MBCiIJ:${this}.MBCiIJ";
  String methodA() => "MBCiIJ:${this}.A->${super.methodA()}";
  String methodB() => "MBCiIJ:${this}.B->${super.methodB()}";
  String methodC() => "MBCiIJ:${this}.C->${super.methodC()}";
  String methodI() => "MBCiIJ:${this}.I";
  String methodJ() => "MBCiIJ:${this}.J";
}


// Abstract mixin, doesn't implement its interface.
mixin MiIJ implements I, J {
  String toString() => "${super.toString()}&MiIJ";
}


// Applications of the mixins.

class COaM = O with M;

class COaM_2 extends O with M {}

class CBaM = B with M;

class CBaM_2 extends B with M {}

class COaMO = O with MO;

class COaMO_2 extends O with MO {}

class CBaMO = B with MO;

class CBaMO_2 extends B with MO {}

class COaMOiIJ = O with MOiIJ;

class COaMOiIJ_2 extends O with MOiIJ {}

class CBaMBiIJ = B with MBiIJ;

class CBaMBiIJ_2 extends B with MBiIJ {}

class CAaMA = A with MA;

class CAaMA_2 extends A with MA {}

class CBaMA = B with MA;

class CBaMA_2 extends B with MA {}

class CAaMAiBC = A with MAiBC;

class CAaMAiBC_2 extends A with MAiBC {}

class CBaMAiBC = B with MAiBC;

class CBaMAiBC_2 extends B with MAiBC {}

class CBCaMBC = BC with MBC;

class CBCaMBC_2 extends BC with MBC {}

class CAaMAiBCaMBC = CAaMAiBC with MBC;

class CAaMAiBCaMBC_2 extends CAaMAiBC with MBC {}

class CBCaMBCiIJ = BC with MBCiIJ;

class CBCaMBCiIJ_2 extends BC with MBCiIJ {}

class CAaMAiBCaMBCiIJ = CAaMAiBC with MBCiIJ;

class CAaMAiBCaMBCiIJ_2 extends CAaMAiBC with MBCiIJ {}

// Abstract mixin application does not implement I and J.
abstract class OaMiIJ = O with MiIJ;

// Concrete subclass of abstract mixin appliction
class COaMiIJ extends OaMiIJ {
  String toString() => "${super.toString()}:COaMiIJ";
  String methodI() => "COaMiIJ:${this}.I";
  String methodJ() => "COaMiIJ:${this}.J";
}

// Abstract class with mixin application and does not implement I and J.
abstract class OaMiIJ_2 extends O with MiIJ {}

// Concrete subclass of abstract mixin appliction
class COaMiIJ_2 extends OaMiIJ_2 {
  String toString() => "${super.toString()}:COaMiIJ";
  String methodI() => "COaMiIJ:${this}.I";
  String methodJ() => "COaMiIJ:${this}.J";
}

// Test of `class C with M` syntax.
class CwithM with M {}
class CeOwithM extends Object with M {}

// Test that the mixin applications behave as expected.
void main() {
  {
    for (dynamic o in [COaM(), COaM_2()]) {
      Expect.type<O>(o);
      Expect.type<M>(o);
      Expect.equals("?&M", "$o");
      Expect.equals("M:$o.M", o.methodM());
    }
  }

  {
    for (dynamic o in [CBaM(), CBaM_2()]) {
      Expect.type<B>(o);
      Expect.type<M>(o);
      Expect.equals("?&M", "$o");
      Expect.equals("B:$o.B", o.methodB());
      Expect.equals("M:$o.M", (o as M).methodM());
    }
  }

  {
    for (dynamic o in [COaMO(), COaMO_2()]) {
      Expect.type<O>(o);
      Expect.type<MO>(o);
      Expect.equals("O&MO", "$o");
      Expect.equals("MO:$o.MO", o.methodMO());
    }
  }

  {
    for (dynamic o in [CBaMO(), CBaMO_2()]) {
      Expect.type<B>(o);
      Expect.type<MO>(o);
      Expect.equals("B&MO", "$o");
      Expect.equals("MO:$o.MO", (o as MO).methodMO());
      // Re-assign to cancel out type promotion from previous "as" expression.
      o = o as dynamic;
      Expect.equals("B:$o.B", o.methodB());
    }
  }

  {
    for (dynamic o in [COaMOiIJ(), COaMOiIJ_2()]) {
      Expect.type<O>(o);
      Expect.type<I>(o);
      Expect.type<J>(o);
      Expect.type<MOiIJ>(o);
      Expect.equals("O&MOiIJ", "$o");
      Expect.equals("MOiIJ:$o.MOiIJ", o.methodMOiIJ());
      Expect.equals("MOiIJ:$o.I", o.methodI());
      Expect.equals("MOiIJ:$o.J", o.methodJ());
    }
  }

  {
    for (dynamic o in [CBaMBiIJ(), CBaMBiIJ_2()]) {
      Expect.type<B>(o);
      Expect.type<I>(o);
      Expect.type<J>(o);
      Expect.type<MBiIJ>(o);
      Expect.equals("B&MBiIJ", "$o");
      Expect.equals("MBiIJ:$o.MBiIJ", o.methodMOiIJ());
      Expect.equals("B:$o.B", o.methodB());
      Expect.equals("MBiIJ:$o.I", o.methodI());
      Expect.equals("MBiIJ:$o.J", o.methodJ());
    }
  }

  {
    for (dynamic o in [CAaMA(), CAaMA_2()]) {
      Expect.type<A>(o);
      Expect.type<MA>(o);
      Expect.equals("A&MA", "$o");
      Expect.equals("MA:$o.MA", o.methodMA());
      Expect.equals("MA:$o.A->A:$o.A", o.methodA());
    }
  }

  {
    for (dynamic o in [CBaMA(), CBaMA_2()]) {
      Expect.type<B>(o);
      Expect.type<MA>(o);
      Expect.equals("B&MA", "$o");
      Expect.equals("MA:$o.MA", (o as MA).methodMA());
      Expect.equals("MA:$o.A->B:$o.A", (o as MA).methodA());
      // Re-assign to cancel out type promotion from previous "as" expression.
      o = o as dynamic;
      Expect.equals("B:$o.B", o.methodB());
    }
  }

  {
    for (dynamic o in [CAaMAiBC(), CAaMAiBC_2()]) {
      Expect.type<A>(o);
      Expect.type<B>(o);
      Expect.type<C>(o);
      Expect.type<MAiBC>(o);
      Expect.equals("A&MAiBC", "$o");
      Expect.equals("MAiBC:$o.MAiBC", o.methodMAiBC());
      Expect.equals("MAiBC:$o.A->A:$o.A", o.methodA());
      Expect.equals("MAiBC:$o.B", o.methodB());
      Expect.equals("MAiBC:$o.C", o.methodC());
    }
  }

  {
    for (dynamic o in [CBaMAiBC(), CBaMAiBC_2()]) {
      Expect.type<A>(o);
      Expect.type<B>(o);
      Expect.type<C>(o);
      Expect.type<MAiBC>(o);
      Expect.equals("B&MAiBC", "$o");
      Expect.equals("MAiBC:$o.MAiBC", o.methodMAiBC());
      Expect.equals("MAiBC:$o.A->B:$o.A", o.methodA());
      Expect.equals("MAiBC:$o.B", o.methodB());
      Expect.equals("MAiBC:$o.C", o.methodC());
    }
  }

  {
    for (dynamic o in [CBCaMBC(), CBCaMBC_2()]) {
      Expect.type<BC>(o);
      Expect.type<MBC>(o);
      Expect.equals("BC&MBC", "$o");
      Expect.equals("MBC:$o.MBC", o.methodMBC());
      Expect.equals("MBC:$o.A->BC:$o.A->C:$o.A->A:$o.A", o.methodA());
      Expect.equals("MBC:$o.B->BC:$o.B", o.methodB());
      Expect.equals("MBC:$o.C->BC:$o.C->C:$o.C", o.methodC());
    }
  }

  {
    // Mixin on top of mixin application.
    for (dynamic o in [CAaMAiBCaMBC(), CAaMAiBCaMBC_2()]) {
      Expect.type<CAaMAiBC>(o);
      Expect.type<MBC>(o);
      Expect.equals("A&MAiBC&MBC", "$o");
      Expect.equals("MBC:$o.MBC", (o as MBC).methodMBC());
      // Re-assign to cancel out type promotion from previous "as" expression.
      o = o as dynamic;
      Expect.equals("MAiBC:$o.MAiBC", o.methodMAiBC());
      Expect.equals("MBC:$o.A->MAiBC:$o.A->A:$o.A", o.methodA());
      Expect.equals("MBC:$o.B->MAiBC:$o.B", o.methodB());
      Expect.equals("MBC:$o.C->MAiBC:$o.C", o.methodC());
    }
  }

  {
    for (dynamic o in [CBCaMBCiIJ(), CBCaMBCiIJ_2()]) {
      Expect.type<BC>(o);
      Expect.type<MBCiIJ>(o);
      Expect.type<I>(o);
      Expect.type<J>(o);
      Expect.equals("BC&MBCiIJ", "$o");
      Expect.equals("MBCiIJ:$o.MBCiIJ", o.methodMBCiIJ());
      Expect.equals("MBCiIJ:$o.A->BC:$o.A->C:$o.A->A:$o.A", o.methodA());
      Expect.equals("MBCiIJ:$o.B->BC:$o.B", o.methodB());
      Expect.equals("MBCiIJ:$o.C->BC:$o.C->C:$o.C", o.methodC());
      Expect.equals("MBCiIJ:$o.I", o.methodI());
      Expect.equals("MBCiIJ:$o.J", o.methodJ());
    }
  }

  {
    // Mixin on top of mixin application.
    for (dynamic o in [CAaMAiBCaMBCiIJ(), CAaMAiBCaMBCiIJ_2()]) {
      Expect.type<CAaMAiBC>(o);
      Expect.type<MBCiIJ>(o);
      Expect.type<I>(o);
      Expect.type<J>(o);
      Expect.equals("A&MAiBC&MBCiIJ", "$o");
      Expect.equals("MBCiIJ:$o.MBCiIJ", o.methodMBCiIJ());
      Expect.equals("MAiBC:$o.MAiBC", (o as CAaMAiBC).methodMAiBC());
      // Re-assign to cancel out type promotion from previous "as" expression.
      o = o as dynamic;
      Expect.equals("MBCiIJ:$o.A->MAiBC:$o.A->A:$o.A", o.methodA());
      Expect.equals("MBCiIJ:$o.B->MAiBC:$o.B", o.methodB());
      Expect.equals("MBCiIJ:$o.C->MAiBC:$o.C", o.methodC());
      Expect.equals("MBCiIJ:$o.I", o.methodI());
      Expect.equals("MBCiIJ:$o.J", o.methodJ());
    }
  }

  {
    // Abstract mixin application, concrete subclass.
    for (dynamic o in [COaMiIJ(), COaMiIJ_2()]) {
      Expect.type<O>(o);
      Expect.type<MiIJ>(o);
      Expect.isTrue(o is OaMiIJ || o is OaMiIJ_2,
          "`$o` should subtype OaMiIJ or OaMiIJ_2");
      Expect.type<I>(o);
      Expect.type<J>(o);
      Expect.equals("O&MiIJ:COaMiIJ", "$o");
      Expect.equals("COaMiIJ:$o.I", o.methodI());
      Expect.equals("COaMiIJ:$o.J", o.methodJ());
    }
  }

  Expect.equals(CeOwithM().toString(), CwithM().toString());

  {
    // Regression test for private fields.
    var c = PrivateFieldClass();
    Expect.equals(42, c._foo);
  }
}


mixin PrivateFieldMixin {
  int _foo = 40;
}

class PrivateFieldClass with PrivateFieldMixin {
  int get _foo => super._foo + 2;
}
