// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum GenericEnum<X> {
  a<int>(),
  b<String>(),
  c<bool>(),
}

void exhaustiveGenericSwitch(GenericEnum<dynamic> e) {
  /*
   checkingOrder={GenericEnum<dynamic>,GenericEnum.a,GenericEnum.b,GenericEnum.c},
   subtypes={GenericEnum.a,GenericEnum.b,GenericEnum.c},
   type=GenericEnum<dynamic>
  */
  switch (e) {
    /*space=GenericEnum.a*/
    case GenericEnum.a:
      print('a');
      break;
    /*space=GenericEnum.b*/
    case GenericEnum.b:
      print('b');
      break;
    /*space=GenericEnum.c*/
    case GenericEnum.c:
      print('c');
      break;
  }
}

void exhaustiveGenericSwitchTyped(GenericEnum<int> e) {
  /*
   checkingOrder={GenericEnum<int>,GenericEnum.a},
   subtypes={GenericEnum.a},
   type=GenericEnum<int>
  */
  switch (e) {
    /*space=GenericEnum.a*/
    case GenericEnum.a:
      print('a');
      break;
  }
}

void exhaustiveGenericSwitchTypeVariable<T1>(GenericEnum<T1> e) {
  /*
   checkingOrder={GenericEnum<T1>,GenericEnum.a,GenericEnum.b,GenericEnum.c},
   subtypes={GenericEnum.a,GenericEnum.b,GenericEnum.c},
   type=GenericEnum<T1>
  */
  switch (e) {
    /*space=GenericEnum.a*/
    case GenericEnum.a:
      print('a');
      break;
    /*space=GenericEnum.b*/
    case GenericEnum.b:
      print('b');
      break;
    /*space=GenericEnum.c*/
    case GenericEnum.c:
      print('c');
      break;
  }
}

void exhaustiveGenericSwitchBounded<T2 extends num>(GenericEnum<T2> e) {
  /*
   checkingOrder={GenericEnum<T2>,GenericEnum.a},
   subtypes={GenericEnum.a},
   type=GenericEnum<T2>
  */
  switch (e) {
    /*space=GenericEnum.a*/
    case GenericEnum.a:
      print('a');
      break;
  }
}

void nonExhaustiveGenericSwitchTypeVariable<T3>(GenericEnum<T3> e) {
  /*
   checkingOrder={GenericEnum<T3>,GenericEnum.a,GenericEnum.b,GenericEnum.c},
   error=non-exhaustive:GenericEnum.c,
   subtypes={GenericEnum.a,GenericEnum.b,GenericEnum.c},
   type=GenericEnum<T3>
  */
  switch (e) {
    /*space=GenericEnum.a*/
    case GenericEnum.a:
      print('a');
      break;
    /*space=GenericEnum.b*/
    case GenericEnum.b:
      print('b');
      break;
  }
}

void exhaustiveGenericSwitchTypeVariableByType<T4>(GenericEnum<T4> e) {
  /*
   checkingOrder={GenericEnum<T4>,GenericEnum.a,GenericEnum.b,GenericEnum.c},
   subtypes={GenericEnum.a,GenericEnum.b,GenericEnum.c},
   type=GenericEnum<T4>
  */
  switch (e) {
    /*space=GenericEnum.a*/
    case GenericEnum.a:
      print('a');
      break;
    /*space=GenericEnum.b*/
    case GenericEnum.b:
      print('b');
      break;
    /*space=GenericEnum<T4>*/
    case GenericEnum<T4> e:
      print('_');
  }
}

void nonExhaustiveGenericSwitchTypeVariableByType<T5, S5>(GenericEnum<T5> e) {
  /*
   checkingOrder={GenericEnum<T5>,GenericEnum.a,GenericEnum.b,GenericEnum.c},
   error=non-exhaustive:GenericEnum.c,
   subtypes={GenericEnum.a,GenericEnum.b,GenericEnum.c},
   type=GenericEnum<T5>
  */
  switch (e) {
    /*space=GenericEnum.a*/
    case GenericEnum.a:
      print('a');
      break;
    /*space=GenericEnum.b*/
    case GenericEnum.b:
      print('b');
      break;
    /*space=GenericEnum<S5>*/
    case GenericEnum<S5> e:
      print('<S>');
  }
}
