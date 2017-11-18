// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A<T> {
  List<T> x;
  void set y(List<T> value) {}
}

test() {
  A<int> a_int = new A<int>();
  A<Object> a_object = new A<Object>();
  A<dynamic> a_dynamic = new A<dynamic>();
  var /*@type=List<int>*/ x_int =
      a_int. /*@target=A::x*/ x = /*@typeArgs=int*/ [0];
  var /*@type=List<int>*/ y_int =
      a_int. /*@target=A::y*/ y = /*@typeArgs=int*/ [0];
  var /*@type=List<Object>*/ x_object =
      a_object. /*@target=A::x*/ x = /*@typeArgs=Object*/ [0];
  var /*@type=List<Object>*/ y_object =
      a_object. /*@target=A::y*/ y = /*@typeArgs=Object*/ [0];
  var /*@type=List<dynamic>*/ x_dynamic =
      a_dynamic. /*@target=A::x*/ x = /*@typeArgs=dynamic*/ [0];
  var /*@type=List<dynamic>*/ y_dynamic =
      a_dynamic. /*@target=A::y*/ y = /*@typeArgs=dynamic*/ [0];
  var /*@type=List<int>*/ x_int_explicit = a_int. /*@target=A::x*/ x = <int>[0];
  var /*@type=List<int>*/ y_int_explicit = a_int. /*@target=A::y*/ y = <int>[0];
  var /*@type=List<int>*/ x_object_explicit =
      a_object. /*@target=A::x*/ x = <int>[0];
  var /*@type=List<int>*/ y_object_explicit =
      a_object. /*@target=A::y*/ y = <int>[0];
  var /*@type=List<int>*/ x_dynamic_explicit =
      a_dynamic. /*@target=A::x*/ x = <int>[0];
  var /*@type=List<int>*/ y_dynamic_explicit =
      a_dynamic. /*@target=A::y*/ y = <int>[0];
  List<int> x_int_downward = a_int. /*@target=A::x*/ x = /*@typeArgs=int*/ [0];
  List<int> y_int_downward = a_int. /*@target=A::y*/ y = /*@typeArgs=int*/ [0];
  List<int> x_object_downward =
      a_object. /*@target=A::x*/ x = /*@typeArgs=Object*/ [0];
  List<int> y_object_downward =
      a_object. /*@target=A::y*/ y = /*@typeArgs=Object*/ [0];
  List<int> x_dynamic_downward =
      a_dynamic. /*@target=A::x*/ x = /*@typeArgs=dynamic*/ [0];
  List<int> y_dynamic_downward =
      a_dynamic. /*@target=A::y*/ y = /*@typeArgs=dynamic*/ [0];
}

main() {}
