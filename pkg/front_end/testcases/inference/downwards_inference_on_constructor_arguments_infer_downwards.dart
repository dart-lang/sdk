// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class F0 {
  F0(List<int> a) {}
}

class F1 {
  F1({List<int> a}) {}
}

class F2 {
  F2(Iterable<int> a) {}
}

class F3 {
  F3(Iterable<Iterable<int>> a) {}
}

class F4 {
  F4({Iterable<Iterable<int>> a}) {}
}

void main() {
  new F0(/*@typeArgs=int*/ []);
  new F0(/*@typeArgs=int*/ [3]);
  new F0(
      /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  new F0(/*@typeArgs=int*/ [
    /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
    3
  ]);

  new F1(a: /*@typeArgs=int*/ []);
  new F1(a: /*@typeArgs=int*/ [3]);
  new F1(a: /*@typeArgs=int*/ [
    /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"
  ]);
  new F1(a: /*@typeArgs=int*/ [
    /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
    3
  ]);

  new F2(/*@typeArgs=int*/ []);
  new F2(/*@typeArgs=int*/ [3]);
  new F2(
      /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  new F2(/*@typeArgs=int*/ [
    /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
    3
  ]);

  new F3(/*@typeArgs=Iterable<int>*/ []);
  new F3(/*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [3]
  ]);
  new F3(/*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]
  ]);
  new F3(/*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
    /*@typeArgs=int*/ [3]
  ]);

  new F4(a: /*@typeArgs=Iterable<int>*/ []);
  new F4(a: /*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [3]
  ]);
  new F4(a: /*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]
  ]);
  new F4(a: /*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
    /*@typeArgs=int*/ [3]
  ]);
}
