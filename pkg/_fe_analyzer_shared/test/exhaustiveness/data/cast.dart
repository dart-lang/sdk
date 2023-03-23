// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int field;

  A(this.field);
}

sealed class B {}
class C extends B {}
class D extends B {}
class E extends B {}

sealed class F<T> {}
class G<T> extends F<T> {}
class H extends F<int> {}
class I<T, S> extends F<T> {}

enum Enum<T> {
  a1<int>(),
  a2<int>(),
  b1<String>(),
  b2<String>(),
  c1<bool>(),
  c2<bool>(),
}

simpleCast(o1, o2) {
  var a = /*
   subtypes={Object,Null},
   type=Object?
  */switch (o1) {
    _ as A /*space=()*/=> 0,
    _ /*
     error=unreachable,
     space=()
    */=> 1
  };

  var b = /*
   subtypes={Object,Null},
   type=Object?
  */switch (o2) {
    _ as A /*space=()*/=> 0,
  };
}

restrictedCase(o1, o2) {
  // Cast shouldn't match everything, because even though it doesn't throw,
  // it might not match.
  var a = /*
   fields={field:-},
   subtypes={Object,Null},
   type=Object?
  */switch (o1) {
    A(field: 42) as A /*space=A(field: 42)|Null*/=> 0,
    _ /*space=()*/=> 1
  };

  var b = /*
   error=non-exhaustive:Object(),
   fields={field:-},
   subtypes={Object,Null},
   type=Object?
  */switch (o2) {
    A(field: 42) as A /*space=A(field: 42)|Null*/=> 0,
  };
}

sealedCast(B b1, B b2) {
  /*
   subtypes={C,D,E},
   type=B
  */
  switch (b1) {
    /*space=C*/
    case C():
    /*space=D|C|E*/
    case D() as D:
  }
  /*
   subtypes={C,D,E},
   type=B
  */
  switch (b2) {
    /*space=D*/
    case D():
    /*space=C|D|E*/
    case C c as C:
  }
}

genericSealedCast<T>(F<T> f1, F<T> f2) {
  /*
   error=non-exhaustive:I<dynamic, dynamic>(),
   subtypes={G<T>,H,I<dynamic, dynamic>},
   type=F<T>
  */
  switch (f1) {
    /*space=G<T>*/
    case G<T>():
    /*space=H*/
    case H() as H:
  }
  /*
   error=non-exhaustive:H(),
   subtypes={G<T>,H,I<dynamic, dynamic>},
   type=F<T>
  */
  switch (f2) {
    /*space=G<T>*/
    case G<T>():
    /*space=I<dynamic, dynamic>*/
    case I() as I<dynamic, dynamic>:
  }
}


nullCast(A? a1, A? a2) {
  var b1 = /*
   subtypes={A,Null},
   type=A?
  */switch (a1) {
    A() as A /*space=A?*/=> 0,
  };
  var b2 = /*
   subtypes={A,Null},
   type=A?
  */switch (a2) {
    Null _ as Null /*space=A?*/=> 0,
  };
}

enumCast(Enum e) {
  /*
   subtypes={Enum.a1,Enum.a2,Enum.b1,Enum.b2,Enum.c1,Enum.c2},
   type=Enum<dynamic>
  */
  switch (e) {
    /*space=Enum<int>|Enum.b1|Enum.b2|Enum.c1|Enum.c2*/
    case Enum<int>() as Enum<int>:
      return 0;
  }
  /*
   subtypes={Enum.a1,Enum.a2,Enum.b1,Enum.b2,Enum.c1,Enum.c2},
   type=Enum<dynamic>
  */
  switch (e) {
    /*space=Enum.a1*/
    case Enum.a1:
    /*space=Enum.a2*/
    case Enum.a2:
      return 0;
    /*space=Enum<String>|Enum.a1|Enum.a2|Enum.c1|Enum.c2*/
    case Enum<String> e as Enum<String>:
      return 1;
  }
}

unrelatedCast(B b1, B? b2) {
  /*
   error=non-exhaustive:C(),
   subtypes={C,D,E},
   type=B
  */
  switch (b1) {
    /*space=H*/
    case H() as H:
  }
  /*
   error=non-exhaustive:C(),
   expandedSubtypes={C,D,E,Null},
   subtypes={B,Null},
   type=B?
  */
  switch (b2) {
    /*space=H*/
    case H h as H:
  }
}

sealed class J {}
class K extends J {}
sealed class L extends J {}
class M extends L {}
class N extends L {}
class O extends N {}

exhaustiveNested(J j1, J j2, J j3, J j4, J j5, J j6) {
  /*
   expandedSubtypes={K,M,N},
   subtypes={K,L},
   type=J
  */
  switch (j1) {
  /*space=J*/
    case J() as J:
  }
  /*
   expandedSubtypes={K,M,N},
   subtypes={K,L},
   type=J
  */
  switch (j2) {
  /*space=K|M|N*/
    case K() as K:
  }
  /*
   expandedSubtypes={K,M,N},
   subtypes={K,L},
   type=J
  */
  switch (j3) {
  /*space=L|K*/
    case L() as L:
  }
  /*
   expandedSubtypes={K,M,N},
   subtypes={K,L},
   type=J
  */
  switch (j4) {
  /*space=M|K|N*/
    case M() as M:
  }
  /*
   expandedSubtypes={K,M,N},
   subtypes={K,L},
   type=J
  */
  switch (j5) {
  /*space=N|K|M*/
    case N() as N:
  }
  /*
   expandedSubtypes={K,M,N},
   subtypes={K,L},
   type=J
  */
  switch (j6) {
    /*space=O|K|M*/
    case O() as O:
    /*space=N*/case N():
  }
}

nonExhaustiveNested(J j) {
  /*
   error=non-exhaustive:N(),
   expandedSubtypes={K,M,N},
   subtypes={K,L},
   type=J
  */
  switch (j) {
    /*space=O|K|M*/
    case O() as O:
  }
}

exhaustiveNestedMultiple(J j1, J j2, J j3, J j4, J j5, J j6) {
  /*
   expandedSubtypes={K,M,N},
   subtypes={K,L},
   type=J
  */
  switch (j1) {
    /*space=K*/
    case K():
    /*space=J*/
    case J() as J:
  }
  /*
   expandedSubtypes={K,M,N},
   subtypes={K,L},
   type=J
  */
  switch (j2) {
    /*space=M*/
    case M():
    /*space=K|M|N*/
    case K() as K:
  }
  /*
   expandedSubtypes={K,M,N},
   subtypes={K,L},
   type=J
  */
  switch (j3) {
    /*space=K*/
    case K():
    /*space=L|K*/
    case L() as L:
  }
  /*
   expandedSubtypes={K,M,N},
   subtypes={K,L},
   type=J
  */
  switch (j4) {
    /*space=K*/
    case K():
    /*space=M|K|N*/
    case M() as M:
  }
  /*
   expandedSubtypes={K,M,N},
   subtypes={K,L},
   type=J
  */
  switch (j5) {
    /*space=K*/
    case K():
    /*space=N|K|M*/
    case N() as N:
  }
  /*
   error=non-exhaustive:N(),
   expandedSubtypes={K,M,N},
   subtypes={K,L},
   type=J
  */switch (j6) {
    /*space=M*/case M():
  /*space=O|K|M*/
    case O() as O:
  }
}
