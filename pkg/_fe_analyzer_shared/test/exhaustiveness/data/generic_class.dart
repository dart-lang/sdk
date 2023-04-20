// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {}

switchADynamic(A<dynamic> o) {
  var a = /*type=A<dynamic>*/
      switch (o) {
    A() /*space=A<dynamic>*/ => 0,
  };
  var b = /*type=A<dynamic>*/
      switch (o) {
    A<dynamic>() /*space=A<dynamic>*/ => 0,
  };
}

switchANum(A<num> o) {
  var a = /*type=A<num>*/
      switch (o) {
    A() /*space=A<num>*/ => 0,
  };
  var b = /*type=A<num>*/
      switch (o) {
    A<dynamic>() /*space=A<num>*/ => 0,
  };
  var c = /*type=A<num>*/
      switch (o) {
    A<num>() /*space=A<num>*/ => 0,
  };
  var d1 = /*type=A<num>*/
      switch (o) {
    A<int>() /*space=A<int>*/ => 0,
    _ /*space=A<num>*/ => 1,
  };
  var d2 = /*
   error=non-exhaustive:A<num>(),
   type=A<num>
  */
      switch (o) {
    A<int>() /*space=A<int>*/ => 0,
  };
}

switchAGeneric<T>(A<T> o) {
  var a = /*type=A<T>*/
      switch (o) {
    A() /*space=A<T>*/ => 0,
  };
  var b = /*type=A<T>*/
      switch (o) {
    A<dynamic>() /*space=A<T>*/ => 0,
  };
  var c = /*type=A<T>*/
      switch (o) {
    A<T>() /*space=A<T>*/ => 0,
  };
  var d1 = /*type=A<T>*/
      switch (o) {
    A<int>() /*space=A<int>*/ => 0,
    _ /*space=A<T>*/ => 1,
  };
  var d2 = /*
   error=non-exhaustive:A<T>(),
   type=A<T>
  */
      switch (o) {
    A<int>() /*space=A<int>*/ => 0,
  };
}
