// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class F0<T> {
  F0(List<T> a) {}
}

class F1<T> {
  F1({List<T> a}) {}
}

class F2<T> {
  F2(Iterable<T> a) {}
}

class F3<T> {
  F3(Iterable<Iterable<T>> a) {}
}

class F4<T> {
  F4({Iterable<Iterable<T>> a}) {}
}

void test() {
  new F0<int>(/*@typeArgs=int*/ []);
  new F0<int>(/*@typeArgs=int*/ [3]);
  new F0<int>(
      /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  new F0<int>(/*@typeArgs=int*/ [
    /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
    3
  ]);

  new F1<int>(a: /*@typeArgs=int*/ []);
  new F1<int>(a: /*@typeArgs=int*/ [3]);
  new F1<int>(a: /*@typeArgs=int*/ [
    /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"
  ]);
  new F1<int>(a: /*@typeArgs=int*/ [
    /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
    3
  ]);

  new F2<int>(/*@typeArgs=int*/ []);
  new F2<int>(/*@typeArgs=int*/ [3]);
  new F2<int>(
      /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  new F2<int>(/*@typeArgs=int*/ [
    /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
    3
  ]);

  new F3<int>(/*@typeArgs=Iterable<int>*/ []);
  new F3<int>(/*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [3]
  ]);
  new F3<int>(/*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]
  ]);
  new F3<int>(/*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
    /*@typeArgs=int*/ [3]
  ]);

  new F4<int>(a: /*@typeArgs=Iterable<int>*/ []);
  new F4<int>(a: /*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [3]
  ]);
  new F4<int>(a: /*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]
  ]);
  new F4<int>(a: /*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
    /*@typeArgs=int*/ [3]
  ]);

  new /*@typeArgs=dynamic*/ F3(/*@typeArgs=Iterable<dynamic>*/ []);
  var /*@type=F3<int>*/ f31 = new /*@typeArgs=int*/ F3(/*@typeArgs=List<int>*/ [
    /*@typeArgs=int*/ [3]
  ]);
  var /*@type=F3<String>*/ f32 =
      new /*@typeArgs=String*/ F3(/*@typeArgs=List<String>*/ [
    /*@typeArgs=String*/ ["hello"]
  ]);
  var /*@type=F3<Object>*/ f33 =
      new /*@typeArgs=Object*/ F3(/*@typeArgs=List<Object>*/ [
    /*@typeArgs=String*/ ["hello"],
    /*@typeArgs=int*/ [3]
  ]);

  new /*@typeArgs=dynamic*/ F4(a: /*@typeArgs=Iterable<dynamic>*/ []);
  new /*@typeArgs=int*/ F4(a: /*@typeArgs=List<int>*/ [
    /*@typeArgs=int*/ [3]
  ]);
  new /*@typeArgs=String*/ F4(a: /*@typeArgs=List<String>*/ [
    /*@typeArgs=String*/ ["hello"]
  ]);
  new /*@typeArgs=Object*/ F4(a: /*@typeArgs=List<Object>*/ [
    /*@typeArgs=String*/ ["hello"],
    /*@typeArgs=int*/ [3]
  ]);
}

main() {}
