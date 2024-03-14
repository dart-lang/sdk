// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A<X> {}

class B<Y> extends A<Y> {}

class C extends A<int> {}

class D<Z, W> extends A<W> {}

enum Enum { a, b }

void exhaustiveSwitchGeneric<T1>(A<T1> a) {
  // TODO(johnniwinther): Room for improvement here. We could recognized the
  //  direct passing of type variables in D.
  /*
   checkingOrder={A<T1>,B<T1>,C,D<dynamic, dynamic>},
   error=non-exhaustive:D<dynamic, dynamic>(),
   subtypes={B<T1>,C,D<dynamic, dynamic>},
   type=A<T1>
  */
  switch (a) {
    /*space=B<T1>*/
    case B<T1> b:
      print('B');
      break;
    /*space=C*/
    case C c:
      print('C');
      break;
    /*space=D<dynamic, T1>*/
    case D<dynamic, T1> d:
      print('D');
      break;
  }
}

void exhaustiveSwitchGenericCatchAll<T2>(A<T2> a) {
  /*
   checkingOrder={A<T2>,B<T2>,C,D<dynamic, dynamic>},
   subtypes={B<T2>,C,D<dynamic, dynamic>},
   type=A<T2>
  */
  switch (a) {
    /*space=B<T2>*/
    case B<T2> b:
      print('B');
      break;
    /*space=D<dynamic, T2>*/
    case D<dynamic, T2> d:
      print('D');
      break;
    /*space=A<T2>*/
    case A<T2> _:
      print('_');
      break;
  }
}

void exhaustiveSwitchGenericBounded<T3 extends String>(A<T3> a) {
  // TODO(johnniwinther): Room for improvement here. We could recognized the
  //  direct passing of type variables in D.
  /*
   checkingOrder={A<T3>,B<T3>,D<dynamic, dynamic>},
   error=non-exhaustive:D<dynamic, dynamic>(),
   subtypes={B<T3>,D<dynamic, dynamic>},
   type=A<T3>
  */
  switch (a) {
    /*space=B<T3>*/
    case B<T3> b:
      print('B');
      break;
    /*space=D<dynamic, T3>*/
    case D<dynamic, T3> d:
      print('D');
      break;
  }
}

void nonExhaustiveSwitchWrongGeneric1<T4, S4>(A<T4> a) {
  /*
   checkingOrder={A<T4>,B<T4>,C,D<dynamic, dynamic>},
   error=non-exhaustive:B<T4>();D<dynamic, dynamic>(),
   subtypes={B<T4>,C,D<dynamic, dynamic>},
   type=A<T4>
  */
  switch (a) {
    /*space=B<S4>*/
    case B<S4> b:
      print('B');
      break;
    /*space=C*/
    case C c:
      print('C');
      break;
    /*space=D<dynamic, T4>*/
    case D<dynamic, T4> d:
      print('D');
      break;
  }
}

void nonExhaustiveSwitchWrongGeneric2<T5, S5>(A<T5> a) {
  /*
   checkingOrder={A<T5>,B<T5>,C,D<dynamic, dynamic>},
   error=non-exhaustive:D<dynamic, dynamic>(),
   subtypes={B<T5>,C,D<dynamic, dynamic>},
   type=A<T5>
  */
  switch (a) {
    /*space=B<T5>*/
    case B<T5> b:
      print('B');
      break;
    /*space=C*/
    case C c:
      print('C');
      break;
    /*space=D<dynamic, S5>*/
    case D<dynamic, S5> d:
      print('D');
      break;
  }
}

void exhaustiveSwitch3(A<String> a) {
  // TODO(johnniwinther): Room for improvement here. We could recognized the
  //  direct passing of type variables in D.
  /*
   checkingOrder={A<String>,B<String>,D<dynamic, dynamic>},
   error=non-exhaustive:D<dynamic, dynamic>(),
   subtypes={B<String>,D<dynamic, dynamic>},
   type=A<String>
  */
  switch (a) {
    /*space=B<String>*/
    case B<String> b:
      print('B');
      break;
    /*space=D<dynamic, String>*/
    case D<dynamic, String> d:
      print('D');
      break;
  }
}

void nonExhaustiveSwitch1(A<int> a) {
  /*
   checkingOrder={A<int>,B<int>,C,D<dynamic, dynamic>},
   error=non-exhaustive:D<dynamic, dynamic>(),
   subtypes={B<int>,C,D<dynamic, dynamic>},
   type=A<int>
  */
  switch (a) {
    /*space=B<int>*/
    case B<int> b:
      print('B');
      break;
    /*space=C*/
    case C c:
      print('C');
      break;
  }
}

void nonExhaustiveSwitch2(A<int> a) {
  /*
   checkingOrder={A<int>,B<int>,C,D<dynamic, dynamic>},
   error=non-exhaustive:B<int>();D<dynamic, dynamic>(),
   subtypes={B<int>,C,D<dynamic, dynamic>},
   type=A<int>
  */
  switch (a) {
    /*space=C*/ case C c:
      print('C');
      break;
    /*space=D<dynamic, int>*/ case D<dynamic, int> d:
      print('D');
      break;
  }
}

void nonExhaustiveSwitch3(A<num> a) {
  /*
   checkingOrder={A<num>,B<num>,C,D<dynamic, dynamic>},
   error=non-exhaustive:D<dynamic, dynamic>(),
   subtypes={B<num>,C,D<dynamic, dynamic>},
   type=A<num>
  */
  switch (a) {
    /*space=B<num>*/
    case B<num> b:
      print('B');
      break;
    /*space=C*/
    case C c:
      print('C');
      break;
    /*space=D<num, num>*/
    case D<num, num> d:
      print('D');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(A<dynamic> a) {
  /*
   checkingOrder={A<dynamic>,B<dynamic>,C,D<dynamic, dynamic>},
   subtypes={B<dynamic>,C,D<dynamic, dynamic>},
   type=A<dynamic>
  */
  switch (a) {
    /*space=C*/
    case C c:
      print('C');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(A<int>? a) {
  // TODO(johnniwinther): Room for improvement here. We could recognized the
  //  direct passing of type variables in D.
  /*
   checkingOrder={A<int>?,A<int>,Null,B<int>,C,D<dynamic, dynamic>},
   error=non-exhaustive:D<dynamic, dynamic>(),
   expandedSubtypes={B<int>,C,D<dynamic, dynamic>,Null},
   subtypes={A<int>,Null},
   type=A<int>?
  */
  switch (a) {
    /*space=B<int>*/
    case B<int> b:
      print('B');
      break;
    /*space=C*/
    case C c:
      print('C');
      break;
    /*space=D<dynamic, int>*/
    case D<dynamic, int> d:
      print('D');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(A<int>? a) {
  /*
   checkingOrder={A<int>?,A<int>,Null,B<int>,C,D<dynamic, dynamic>},
   error=non-exhaustive:null,
   expandedSubtypes={B<int>,C,D<dynamic, dynamic>,Null},
   subtypes={A<int>,Null},
   type=A<int>?
  */
  switch (a) {
    /*space=A<int>*/
    case A<int> a:
      print('A');
      break;
  }
}

void nonExhaustiveNullableSwitch2(A<int>? a) {
  /*
   checkingOrder={A<int>?,A<int>,Null,B<int>,C,D<dynamic, dynamic>},
   error=non-exhaustive:D<dynamic, dynamic>(),
   expandedSubtypes={B<int>,C,D<dynamic, dynamic>,Null},
   subtypes={A<int>,Null},
   type=A<int>?
  */
  switch (a) {
    /*space=B<int>*/
    case B<int> b:
      print('B');
      break;
    /*space=C*/
    case C c:
      print('C');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(A<int> a) {
  /*
   checkingOrder={A<int>,B<int>,C,D<dynamic, dynamic>},
   subtypes={B<int>,C,D<dynamic, dynamic>},
   type=A<int>
  */
  switch (a) {
    /*space=B<int>*/
    case B<int> b:
      print('B');
      break;
    /*space=C*/
    case C c:
      print('C');
      break;
    /*space=D<dynamic, int>*/
    case D<dynamic, int> d:
      print('D');
      break;
    /*space=A<int>*/
    case A a:
      print('A');
      break;
  }
}

void unreachableCase2(A<int> a) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  /*
   checkingOrder={A<int>,B<int>,C,D<dynamic, dynamic>},
   subtypes={B<int>,C,D<dynamic, dynamic>},
   type=A<int>
  */
  switch (a) {
    /*space=A<int>*/
    case A<int> a:
      print('A');
      break;
    /*space=Null*/
    case null:
      print('null');
      break;
  }
}

void unreachableCase3(A<int>? a) {
  /*
   checkingOrder={A<int>?,A<int>,Null,B<int>,C,D<dynamic, dynamic>},
   expandedSubtypes={B<int>,C,D<dynamic, dynamic>,Null},
   subtypes={A<int>,Null},
   type=A<int>?
  */
  switch (a) {
    /*space=A<int>*/
    case A<int> a:
      print('A');
      break;
    /*space=Null*/
    case null:
      print('null #1');
      break;
    /*
     error=unreachable,
     space=Null
    */
    case null:
      print('null #2');
      break;
  }
}
