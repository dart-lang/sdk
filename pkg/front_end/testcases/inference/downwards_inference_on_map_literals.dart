// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

void foo([
  Map<int, String> m1 = const {1: "hello"},
  Map<int, String> m2 = const {
    // One error is from type checking and the other is from const evaluation.
    /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE,error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/ "hello":
        "world",
  },
]) {}
void test() {
  {
    Map<int, String> l0 = {};
    Map<int, String> l1 = {3: "hello"};
    Map<int, String> l2 = {
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/ "hello": "hello",
    };
    Map<int, String> l3 = {3: /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/ 3};
    Map<int, String> l4 = {
      3: "hello",
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/ "hello":
          /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/ 3,
    };
  }
  {
    Map<dynamic, dynamic> l0 = {};
    Map<dynamic, dynamic> l1 = {3: "hello"};
    Map<dynamic, dynamic> l2 = {"hello": "hello"};
    Map<dynamic, dynamic> l3 = {3: 3};
    Map<dynamic, dynamic> l4 = {3: "hello", "hello": 3};
  }
  {
    Map<dynamic, String> l0 = {};
    Map<dynamic, String> l1 = {3: "hello"};
    Map<dynamic, String> l2 = {"hello": "hello"};
    Map<dynamic, String> l3 = {3: /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/ 3};
    Map<dynamic, String> l4 = {
      3: "hello",
      "hello": /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/ 3,
    };
  }
  {
    Map<int, dynamic> l0 = {};
    Map<int, dynamic> l1 = {3: "hello"};
    Map<int, dynamic> l2 = {
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/ "hello": "hello",
    };
    Map<int, dynamic> l3 = {3: 3};
    Map<int, dynamic> l4 = {
      3: "hello",
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/ "hello": 3,
    };
  }
  {
    Map<int, String> l0 = /*error:INVALID_CAST_LITERAL_MAP*/ <num, dynamic>{};
    Map<int, String> l1 = /*error:INVALID_CAST_LITERAL_MAP*/ <num, dynamic>{
      3: "hello",
    };
    Map<int, String> l3 = /*error:INVALID_CAST_LITERAL_MAP*/ <num, dynamic>{
      3: 3,
    };
  }
  {
    const Map<int, String> l0 = const {};
    const Map<int, String> l1 = const {3: "hello"};
    const Map<int, String> l2 = const {
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE,error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/ "hello":
          "hello",
    };
    const Map<int, String> l3 = const {
      3: 3 /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE,error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/,
    };
    const Map<int, String> l4 = const {
      3: "hello",
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE,error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/ "hello":
          /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE,error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/ 3,
    };
  }
}

main() {}
