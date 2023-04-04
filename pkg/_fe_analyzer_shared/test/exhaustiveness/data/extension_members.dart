// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A implements I, J {}

class B extends A {}

class C extends A {}

class D extends A {
  D get member => this;
}

abstract class I {}

abstract class J {}

class SubB extends B {}

extension on A {
  A get member => this;
}

extension on B {
  B get member => this;
}

extension on C {
  C get member => this;
}

extension on I {
  B get member => new B();
  A get member2 => new A();
  C get member3 => new C();
}

extension on J {
  num get member => 0;
  A get member2 => new A();
  bool get member3 => true;
}

exhaustiveBCD_Inferred(A a) {
  /*
   checkingOrder={A,B,C,D},
   fields={member:-,B.member:B,C.member:C},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=B(B.member: B (B))*/
    case B(:var member):
    /*space=C(C.member: C (C))*/
    case C(:var member):
    /*space=D(member: D)*/
    case D(:var member):
  }
}

exhaustiveBCD_Typed(A a) {
  /*
   checkingOrder={A,B,C,D},
   fields={member:-,B.member:B,C.member:C},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=B(B.member: B (B))*/
    case B(:B member):
    /*space=C(C.member: C (C))*/
    case C(:C member):
    /*space=D(member: D)*/
    case D(:D member):
  }
}

nonExhaustiveBCD_Restricted(A a) {
  /*
   checkingOrder={A,B,C,D},
   error=non-exhaustive:B(member: B())/B(),
   fields={member:-,B.member:B,C.member:C},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=B(B.member: SubB (B))*/
    case B(:SubB member):
    /*space=C(C.member: C (C))*/
    case C(:C member):
    /*space=D(member: D)*/
    case D(:D member):
  }
}

exhaustiveA(A a) {
  /*
   checkingOrder={A,B,C,D},
   fields={A.member:A},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=A(A.member: B (A))*/
    case A(:B member):
    /*space=A(A.member: C (A))*/
    case A(:C member):
    /*space=A(A.member: D (A))*/
    case A(:D member):
  }
}

exhaustiveI_Inferred(A a) {
  /*
   checkingOrder={A,B,C,D},
   fields={member:-,C.member:C,I.member:B},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=C(C.member: C (C))*/
    case C(:var member):
    /*space=D(member: D)*/
    case D(:var member):
    /*space=A(I.member: B (B))*/
    case I(:var member):
  }
}

exhaustiveI_Typed(A a) {
  /*
   checkingOrder={A,B,C,D},
   fields={member:-,C.member:C,I.member:B},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=C(C.member: C (C))*/
    case C(:C member):
    /*space=D(member: D)*/
    case D(:D member):
    /*space=A(I.member: B (B))*/
    case I(:B member):
  }
}

nonExhaustiveI_Typed(A a) {
  /*
   checkingOrder={A,B,C,D},
   error=non-exhaustive:I(member: B())/B(),
   fields={member:-,C.member:C,I.member:B},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=C(C.member: C (C))*/
    case C(:C member):
    /*space=D(member: D)*/
    case D(:D member):
    /*space=A(I.member: SubB (B))*/
    case I(:SubB member):
  }
}

exhaustiveIJ_Typed(A a) {
  /*
   checkingOrder={A,B,C,D},
   fields={member:-,I.member:B,J.member:num},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=D(member: D)*/
    case D(:D member):
    /*space=A(I.member: C (B))*/
    case I(:C member):
    /*space=A(J.member: int (num))*/
    case J(:int member):
    /*space=A(J.member: double (num))*/
    case J(:double member):
  }
}

unreachableIJ_Typed(A a) {
  /*
   checkingOrder={A,B,C,D},
   fields={member:-,I.member:B,J.member:num},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=D(member: D)*/
    case D(:D member):
    /*space=A(I.member: C (B))*/
    case I(:C member):
    /*space=A(J.member: num (num))*/
    case J(:num member):
    /*
     error=unreachable,
     space=A(J.member: double (num))
    */
    case J(:double member):
  }
}

unreachableIJ_Inferred(A a) {
  /*
   checkingOrder={A,B,C,D},
   fields={member:-,C.member:C,I.member:B,J.member:num},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=C(C.member: C (C))*/
    case C(:var member):
    /*space=D(member: D)*/
    case D(:var member):
    /*space=A(I.member: B (B))*/
    case I(:var member):
    /*
     error=unreachable,
     space=A(J.member: num (num))
    */
    case J(:var member):
  }
}

nonExhaustiveIJ_Restricted(A a) {
  /*
   checkingOrder={A,B,C,D},
   error=non-exhaustive:I(member: B()) && J(member: double())/J(member: double()),
   fields={member:-,C.member:C,I.member:B,J.member:num},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=C(C.member: C (C))*/
    case C(:var member):
    /*space=D(member: D)*/
    case D(:var member):
    /*space=A(J.member: int (num))*/
    case J(:int member):
    /*space=A(I.member: SubB (B))*/
    case I(:SubB member):
  }
}

exhaustiveIJ_Multiple(A a) {
  /*
   checkingOrder={A,B,C,D},
   fields={member:-,C.member:C,I.member:B,I.member2:A,I.member3:C,J.member:num,J.member2:A,J.member3:bool},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=C(C.member: C (C))*/
    case C(:var member):
    /*space=D(member: D)*/
    case D(:var member):
    /*space=A(I.member: C (B), I.member2: A (A), I.member3: C (C))*/
    case I(:C member, :var member2, :var member3):
    /*space=A(J.member: num (num), J.member2: A (A), J.member3: bool (bool))*/
    case J(:var member, :A member2, :var member3):
  }
}

nonExhaustiveIJ_MultipleRestricted(A a) {
  /*
   checkingOrder={A,B,C,D},
   error=non-exhaustive:I(member: B(), member2: B(), member3: C()) && J(member: double(), member2: C(), member3: true)/I(member2: B()) && J(member: double(), member2: C(), member3: true),
   fields={member:-,C.member:C,I.member:B,I.member2:A,I.member3:C,J.member:num,J.member2:A,J.member3:bool},
   subtypes={B,C,D},
   type=A
  */
  switch (a) {
    /*space=C(C.member: C (C))*/
    case C(:var member):
    /*space=D(member: D)*/
    case D(:var member):
    /*space=A(I.member: C (B), I.member2: A (A), I.member3: C (C))*/
    case I(:C member, :var member2, :var member3):
    /*space=A(J.member: num (num), J.member2: B (A), J.member3: bool (bool))*/
    case J(:var member, :B member2, :var member3):
  }
}
