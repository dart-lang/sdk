// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A<X> {}
class B<Y extends num> extends A<Y> {}
class C<Z extends Object> extends A<Z> {}

exhaustiveGeneric<T1>(A<T1> a) {
  /*
   subtypes={B<num>,C<Object>},
   type=A<T1>
  */
  switch (a) {
    /*space=B<num>*/
    case B b:
      print('b');
      break;
    /*space=C<Object>*/
    case C c:
      print('c');
      break;
  }
}

exhaustiveDynamic(A<dynamic> a) {
  /*
   subtypes={B<num>,C<Object>},
   type=A<dynamic>
  */
  switch (a) {
    /*space=B<num>*/
    case B b:
      print('b');
      break;
    /*space=C<Object>*/
    case C c:
      print('c');
      break;
  }
}

exhaustiveGenericFixed<T2>(A<T2> a) {
  /*
   subtypes={B<num>,C<Object>},
   type=A<T2>
  */
  switch (a) {
    /*space=B<num>*/
    case B<num> b:
      print('b');
      break;
    /*space=C<Object>*/
    case C<Object> c:
      print('c');
      break;
  }
}

exhaustiveGenericCatchAll<T3>(A<T3> a) {
  /*
   subtypes={B<num>,C<Object>},
   type=A<T3>
  */
  switch (a) {
    /*space=B<num>*/
    case B<num> b:
      print('b');
      break;
    /*space=A<T3>*/
    case A<T3> _:
      print('_');
      break;
  }
}

nonExhaustiveGeneric<T4>(A<T4> a) {
  /*
   error=non-exhaustive:C<Object>(),
   subtypes={B<num>,C<Object>},
   type=A<T4>
  */
  switch (a) {
    /*space=B<num>*/
    case B b:
      print('b');
      break;
  }
  /*
   error=non-exhaustive:B<num>(),
   subtypes={B<num>,C<Object>},
   type=A<T4>
  */
  switch (a) {
    /*space=C<Object>*/
    case C c:
      print('c');
      break;
  }
}

nonExhaustiveDynamic1(A<dynamic> a) {
  /*
   error=non-exhaustive:C<Object>(),
   subtypes={B<num>,C<Object>},
   type=A<dynamic>
  */
  switch (a) {
    /*space=B<num>*/
    case B b:
      print('b');
      break;
  }
}

nonExhaustiveDynamic2(A<dynamic> a) {
  /*
   error=non-exhaustive:B<num>(),
   subtypes={B<num>,C<Object>},
   type=A<dynamic>
  */
  switch (a) {
    /*space=C<Object>*/
    case C c:
      print('c');
      break;
  }
}

nonExhaustiveGenericFixed<T5>(A<T5> a) {
  /*
   error=non-exhaustive:B<num>(),
   subtypes={B<num>,C<Object>},
   type=A<T5>
  */
  switch (a) {
    /*space=C<Object>*/
    case C<Object> c:
      print('c');
      break;
  }
  /*
   error=non-exhaustive:B<num>(),
   subtypes={B<num>,C<Object>},
   type=A<T5>
  */
  switch (a) {
    /*space=C<Object>*/
    case C<Object> c:
      print('c');
      break;
  }
}

nonExhaustiveGenericCatchAll<T6, S6>(A<T6> a) {
  /*
   error=non-exhaustive:B<num>(),
   subtypes={B<num>,C<Object>},
   type=A<T6>
  */
  switch (a) {
    /*space=C<Object>*/
    case C<Object> c:
      print('c');
      break;
    /*space=A<S6>*/
    case A<S6> _:
      print('_');
      break;
  }
  /*
   error=non-exhaustive:B<num>(),
   subtypes={B<num>,C<Object>},
   type=A<T6>
  */
  switch (a) {
    /*space=C<Object>*/
    case C<Object> c:
      print('c');
      break;
    /*space=A<S6>*/
    case A<S6> _:
      print('_');
      break;
  }
}

nonExhaustiveFixed(A<String> a) {
  /*
   error=non-exhaustive:B<num>(),
   subtypes={B<num>,C<String>},
   type=A<String>
  */
  switch (a) {
    /*space=C<Object>*/
    case C c:
      print('c');
      break;
  }
}
