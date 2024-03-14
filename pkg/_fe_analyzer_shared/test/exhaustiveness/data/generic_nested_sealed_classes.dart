// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A<X> {}

sealed class B<Y> extends A<Y> {}

sealed class C extends A<int> {}

sealed class D<Z, W> extends A<W> {}

class B1<V1> extends B<V1> {}

class B2 extends B<int> {}

class C1 extends C {}

class C2<U1> extends C {}

class D1<V2, U2> extends D<V2, U2> {}

class D2<V3> extends D<int, V3> {}

class D3<U3> extends D<U3, int> {}

class D4 extends D<bool, bool> {}

exhaustiveLevel0<T1>(A<T1> a) {
  /*
   checkingOrder={A<T1>,B<T1>,C,D<dynamic, dynamic>,B1<T1>,B2,C1,C2<dynamic>,D1<dynamic, dynamic>,D2<dynamic>,D3<dynamic>,D4},
   expandedSubtypes={B1<T1>,B2,C1,C2<dynamic>,D1<dynamic, dynamic>,D2<dynamic>,D3<dynamic>,D4},
   subtypes={B<T1>,C,D<dynamic, dynamic>},
   type=A<T1>
  */
  switch (a) {
    /*space=A<T1>*/
    case A<T1> _:
      print('_');
      break;
  }
}

exhaustiveLevel0_1<T2>(A<T2> a) {
  /*
   checkingOrder={A<T2>,B<T2>,C,D<dynamic, dynamic>,B1<T2>,B2,C1,C2<dynamic>,D1<dynamic, dynamic>,D2<dynamic>,D3<dynamic>,D4},
   expandedSubtypes={B1<T2>,B2,C1,C2<dynamic>,D1<dynamic, dynamic>,D2<dynamic>,D3<dynamic>,D4},
   subtypes={B<T2>,C,D<dynamic, dynamic>},
   type=A<T2>
  */
  switch (a) {
    /*space=B<T2>*/
    case B<T2> b:
      print('b');
      break;
    /*space=D<dynamic, T2>*/
    case D<dynamic, T2> d:
      print('d');
      break;
    /*space=A<T2>*/
    case A<T2> _:
      print('_');
      break;
  }
}

exhaustiveLevel1<T3>(A<T3> a) {
  // TODO(johnniwinther): Room for improvement here. We could recognized the
  //  direct passing of type variables in D.
  /*
   checkingOrder={A<T3>,B<T3>,C,D<dynamic, dynamic>,B1<T3>,B2,C1,C2<dynamic>,D1<dynamic, dynamic>,D2<dynamic>,D3<dynamic>,D4},
   error=non-exhaustive:D1<dynamic, dynamic>();D2<dynamic>();D3<dynamic>();D4(),
   expandedSubtypes={B1<T3>,B2,C1,C2<dynamic>,D1<dynamic, dynamic>,D2<dynamic>,D3<dynamic>,D4},
   subtypes={B<T3>,C,D<dynamic, dynamic>},
   type=A<T3>
  */
  switch (a) {
    /*space=B<T3>*/
    case B<T3> b:
      print('b');
      break;
    /*space=C*/
    case C c:
      print('c');
      break;
    /*space=D<dynamic, T3>*/
    case D<dynamic, T3> d:
      print('d');
      break;
  }
}

exhaustiveLevel1b<T3>(B<T3> a) {
  /*
   checkingOrder={B<T3>,B1<T3>,B2},
   subtypes={B1<T3>,B2},
   type=B<T3>
  */
  switch (a) {
    /*space=B<T3>*/
    case B<T3> b:
      print('b');
      break;
  }
  /*
   checkingOrder={B<T3>,B1<T3>,B2},
   subtypes={B1<T3>,B2},
   type=B<T3>
  */
  switch (a) {
    /*space=B1<T3>*/
    case B1<T3> b1:
      print('b1');
      break;
    /*space=B2*/
    case B2 b2:
      print('b2');
      break;
  }
}

exhaustiveLevel2<T4>(A<T4> a) {
  // TODO(johnniwinther): Room for improvement here. We could recognized the
  //  direct passing of type variables in D.
  /*
   checkingOrder={A<T4>,B<T4>,C,D<dynamic, dynamic>,B1<T4>,B2,C1,C2<dynamic>,D1<dynamic, dynamic>,D2<dynamic>,D3<dynamic>,D4},
   error=non-exhaustive:D1<dynamic, dynamic>();D2<dynamic>(),
   expandedSubtypes={B1<T4>,B2,C1,C2<dynamic>,D1<dynamic, dynamic>,D2<dynamic>,D3<dynamic>,D4},
   subtypes={B<T4>,C,D<dynamic, dynamic>},
   type=A<T4>
  */
  switch (a) {
    /*space=B1<T4>*/
    case B1<T4> b1:
      print('b1');
      break;
    /*space=B2*/
    case B2 b2:
      print('b2');
      break;
    /*space=C1*/
    case C1 c1:
      print('c1');
      break;
    /*space=C2<dynamic>*/
    case C2<dynamic> c2:
      print('c2');
      break;
    /*space=D1<dynamic, T4>*/
    case D1<dynamic, T4> d1:
      print('d1');
      break;
    /*space=D2<T4>*/
    case D2<T4> d2:
      print('d2');
      break;
    /*space=D3<dynamic>*/
    case D3<dynamic> d3:
      print('d3');
      break;
    /*space=D4*/ case D4 d4:
      print('d4');
      break;
  }
}

exhaustiveLevel0_1_2<T5>(A<T5> a) {
  /*
   checkingOrder={A<T5>,B<T5>,C,D<dynamic, dynamic>,B1<T5>,B2,C1,C2<dynamic>,D1<dynamic, dynamic>,D2<dynamic>,D3<dynamic>,D4},
   expandedSubtypes={B1<T5>,B2,C1,C2<dynamic>,D1<dynamic, dynamic>,D2<dynamic>,D3<dynamic>,D4},
   subtypes={B<T5>,C,D<dynamic, dynamic>},
   type=A<T5>
  */
  switch (a) {
    /*space=B<T5>*/
    case B<T5> b:
      print('b');
      break;
    /*space=C1*/
    case C1 c1:
      print('c1');
      break;
    /*space=C2<dynamic>*/
    case C2<dynamic> c2:
      print('c2');
      break;
    /*space=A<T5>*/
    case A<T5> _:
      print('_');
      break;
  }
}
