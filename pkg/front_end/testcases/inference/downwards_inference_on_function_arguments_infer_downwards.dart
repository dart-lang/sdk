// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void f0(List<int> a) {}
void f1({List<int> a}) {}
void f2(Iterable<int> a) {}
void f3(Iterable<Iterable<int>> a) {}
void f4({Iterable<Iterable<int>> a}) {}
void test() {
  f0(/*@typeArgs=int*/ []);
  f0(/*@typeArgs=int*/ [3]);
  f0(/*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  f0(/*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello", 3]);

  f1(a: /*@typeArgs=int*/ []);
  f1(a: /*@typeArgs=int*/ [3]);
  f1(a: /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  f1(a: /*@typeArgs=int*/ [
    /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
    3
  ]);

  f2(/*@typeArgs=int*/ []);
  f2(/*@typeArgs=int*/ [3]);
  f2(/*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]);
  f2(/*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello", 3]);

  f3(/*@typeArgs=Iterable<int>*/ []);
  f3(/*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [3]
  ]);
  f3(/*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]
  ]);
  f3(/*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
    /*@typeArgs=int*/ [3]
  ]);

  f4(a: /*@typeArgs=Iterable<int>*/ []);
  f4(a: /*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [3]
  ]);
  f4(a: /*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"]
  ]);
  f4(a: /*@typeArgs=Iterable<int>*/ [
    /*@typeArgs=int*/ [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"],
    /*@typeArgs=int*/ [3]
  ]);
}

main() {}
