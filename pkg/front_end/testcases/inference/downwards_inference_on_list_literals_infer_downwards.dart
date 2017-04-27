// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void foo(
    [List<String> list1 = /*@typeArgs=String*/ const [],
    List<String> list2 = /*@typeArgs=String*/ const [
      /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 42
    ]]) {}

void main() {
  {
    List<int> l0 = /*@typeArgs=int*/ [];
    List<int> l1 = /*@typeArgs=int*/ [3];
    List<int> l2 = /*@typeArgs=int*/ [
      /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"
    ];
    List<int> l3 = /*@typeArgs=int*/ [
      /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
      3
    ];
  }
  {
    List<dynamic> l0 = /*@typeArgs=dynamic*/ [];
    List<dynamic> l1 = /*@typeArgs=dynamic*/ [3];
    List<dynamic> l2 = /*@typeArgs=dynamic*/ ["hello"];
    List<dynamic> l3 = /*@typeArgs=dynamic*/ ["hello", 3];
  }
  {
    List<int> l0 = /*error:INVALID_CAST_LITERAL_LIST*/ <num>[];
    List<int> l1 = /*error:INVALID_CAST_LITERAL_LIST*/ <num>[3];
    List<int> l2 = /*error:INVALID_CAST_LITERAL_LIST*/ <num>[
      /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"
    ];
    List<int> l3 = /*error:INVALID_CAST_LITERAL_LIST*/ <num>[
      /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
      3
    ];
  }
  {
    Iterable<int> i0 = /*@typeArgs=int*/ [];
    Iterable<int> i1 = /*@typeArgs=int*/ [3];
    Iterable<int> i2 = /*@typeArgs=int*/ [
      /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"
    ];
    Iterable<int> i3 = /*@typeArgs=int*/ [
      /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
      3
    ];
  }
  {
    const List<int> c0 = /*@typeArgs=int*/ const [];
    const List<int> c1 = /*@typeArgs=int*/ const [3];
    const List<int> c2 = /*@typeArgs=int*/ const [
      /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"
    ];
    const List<int> c3 = /*@typeArgs=int*/ const [
      /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
      3
    ];
  }
}
