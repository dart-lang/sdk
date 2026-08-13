// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

void foo([
  List<String> list1 = const [],
  List<String> list2 = const [
    /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 42,
  ],
]) {}

void test() {
  {
    List<int> l0 = [];
    List<int> l1 = [3];
    List<int> l2 = [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"];
    List<int> l3 = [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello", 3];
  }
  {
    List<dynamic> l0 = [];
    List<dynamic> l1 = [3];
    List<dynamic> l2 = ["hello"];
    List<dynamic> l3 = ["hello", 3];
  }
  {
    List<int> l0 = /*error:INVALID_CAST_LITERAL_LIST*/ <num>[];
    List<int> l1 = /*error:INVALID_CAST_LITERAL_LIST*/ <num>[3];
    List<int> l2 = /*error:INVALID_CAST_LITERAL_LIST*/ <num>[
      /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
    ];
    List<int> l3 = /*error:INVALID_CAST_LITERAL_LIST*/ <num>[
      /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
      3,
    ];
  }
  {
    Iterable<int> i0 = [];
    Iterable<int> i1 = [3];
    Iterable<int> i2 = [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello"];
    Iterable<int> i3 = [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello", 3];
  }
  {
    const List<int> c0 = const [];
    const List<int> c1 = const [3];
    const List<int> c2 = const [
      /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
    ];
    const List<int> c3 = const [
      /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ "hello",
      3,
    ];
  }
}
