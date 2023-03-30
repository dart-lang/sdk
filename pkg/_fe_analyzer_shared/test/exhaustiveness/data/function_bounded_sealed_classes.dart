// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class A<X> {}

class B<Y extends num Function(dynamic)> extends A<Y> {}

class C<Z extends dynamic Function(num)> extends A<Z> {}

class D<W extends num Function(num)> extends A<W> {}

exhaustiveCovariant<T>(A<T Function(Never)> a) {
  /*
   checkingOrder={A<T Function(Never)>,B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   subtypes={B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   type=A<T Function(Never)>
  */
  switch (a) {
    /*space=B<num Function(dynamic)>*/
    case B b:
      print('b');
      break;
    /*space=C<dynamic Function(num)>*/
    case C c:
      print('c');
      break;
    /*space=D<num Function(num)>*/
    case D d:
      print('d');
      break;
  }
}

exhaustiveContravariant<T>(A<dynamic Function(T)> a) {
  /*
   checkingOrder={A<dynamic Function(T)>,B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   subtypes={B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   type=A<dynamic Function(T)>
  */
  switch (a) {
    /*space=B<num Function(dynamic)>*/
    case B b:
      print('b');
      break;
    /*space=C<dynamic Function(num)>*/
    case C c:
      print('c');
      break;
    /*space=D<num Function(num)>*/
    case D d:
      print('d');
      break;
  }
}

exhaustiveBivariant<T>(A<T Function(T)> a) {
  /*
   checkingOrder={A<T Function(T)>,B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   subtypes={B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   type=A<T Function(T)>
  */
  switch (a) {
    /*space=B<num Function(dynamic)>*/
    case B b:
      print('b');
      break;
    /*space=C<dynamic Function(num)>*/
    case C c:
      print('c');
      break;
    /*space=D<num Function(num)>*/
    case D d:
      print('d');
      break;
  }
}

nonExhaustiveCovariant<T>(A<T Function(Never)> a) {
  /*
   checkingOrder={A<T Function(Never)>,B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   error=non-exhaustive:B<num Function(dynamic)>(),
   subtypes={B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   type=A<T Function(Never)>
  */
  switch (a) {
    /*space=C<dynamic Function(num)>*/
    case C c:
      print('c');
      break;
    /*space=D<num Function(num)>*/
    case D d:
      print('d');
      break;
  }
  /*
   checkingOrder={A<T Function(Never)>,B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   error=non-exhaustive:C<dynamic Function(num)>(),
   subtypes={B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   type=A<T Function(Never)>
  */
  switch (a) {
    /*space=B<num Function(dynamic)>*/
    case B b:
      print('b');
      break;
    /*space=D<num Function(num)>*/
    case D d:
      print('d');
      break;
  }
  /*
   checkingOrder={A<T Function(Never)>,B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   error=non-exhaustive:D<num Function(num)>(),
   subtypes={B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   type=A<T Function(Never)>
  */
  switch (a) {
    /*space=B<num Function(dynamic)>*/
    case B b:
      print('b');
      break;
    /*space=C<dynamic Function(num)>*/
    case C c:
      print('c');
      break;
  }
}

nonExhaustiveContravariant<T>(A<dynamic Function(T)> a) {
  /*
   checkingOrder={A<dynamic Function(T)>,B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   error=non-exhaustive:B<num Function(dynamic)>(),
   subtypes={B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   type=A<dynamic Function(T)>
  */
  switch (a) {
    /*space=C<dynamic Function(num)>*/
    case C c:
      print('c');
      break;
    /*space=D<num Function(num)>*/
    case D d:
      print('d');
      break;
  }
  /*
   checkingOrder={A<dynamic Function(T)>,B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   error=non-exhaustive:C<dynamic Function(num)>(),
   subtypes={B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   type=A<dynamic Function(T)>
  */
  switch (a) {
    /*space=B<num Function(dynamic)>*/
    case B b:
      print('b');
      break;
    /*space=D<num Function(num)>*/
    case D d:
      print('d');
      break;
  }
  /*
   checkingOrder={A<dynamic Function(T)>,B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   error=non-exhaustive:D<num Function(num)>(),
   subtypes={B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   type=A<dynamic Function(T)>
  */
  switch (a) {
    /*space=B<num Function(dynamic)>*/
    case B b:
      print('b');
      break;
    /*space=C<dynamic Function(num)>*/
    case C c:
      print('c');
      break;
  }
}

nonExhaustiveBivariant<T>(A<T Function(T)> a) {
  /*
   checkingOrder={A<T Function(T)>,B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   error=non-exhaustive:B<num Function(dynamic)>(),
   subtypes={B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   type=A<T Function(T)>
  */
  switch (a) {
    /*space=C<dynamic Function(num)>*/
    case C c:
      print('c');
      break;
    /*space=D<num Function(num)>*/
    case D d:
      print('d');
      break;
  }
  /*
   checkingOrder={A<T Function(T)>,B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   error=non-exhaustive:C<dynamic Function(num)>(),
   subtypes={B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   type=A<T Function(T)>
  */
  switch (a) {
    /*space=B<num Function(dynamic)>*/
    case B b:
      print('b');
      break;
    /*space=D<num Function(num)>*/
    case D d:
      print('d');
      break;
  }
  /*
   checkingOrder={A<T Function(T)>,B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   error=non-exhaustive:D<num Function(num)>(),
   subtypes={B<num Function(dynamic)>,C<dynamic Function(num)>,D<num Function(num)>},
   type=A<T Function(T)>
  */
  switch (a) {
    /*space=B<num Function(dynamic)>*/
    case B b:
      print('b');
      break;
    /*space=C<dynamic Function(num)>*/
    case C c:
      print('c');
      break;
  }
}
