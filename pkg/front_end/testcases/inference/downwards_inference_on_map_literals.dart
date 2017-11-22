// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void foo(
    [Map<int, String> m1 = /*@typeArgs=int, String*/ const {1: "hello"},
    Map<int, String> m2 = /*@typeArgs=int, String*/ const {
      // One error is from type checking and the other is from const evaluation.
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE,error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/ "hello":
          "world"
    }]) {}
void test() {
  {
    Map<int, String> l0 = /*@typeArgs=int, String*/ {};
    Map<int, String> l1 = /*@typeArgs=int, String*/ {3: "hello"};
    Map<int, String> l2 = /*@typeArgs=int, String*/ {
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/ "hello": "hello"
    };
    Map<int, String> l3 = /*@typeArgs=int, String*/ {
      3: /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/ 3
    };
    Map<int, String> l4 = /*@typeArgs=int, String*/ {
      3: "hello",
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/ "hello":
          /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/ 3
    };
  }
  {
    Map<dynamic, dynamic> l0 = /*@typeArgs=dynamic, dynamic*/ {};
    Map<dynamic, dynamic> l1 = /*@typeArgs=dynamic, dynamic*/ {3: "hello"};
    Map<dynamic, dynamic> l2 = /*@typeArgs=dynamic, dynamic*/ {
      "hello": "hello"
    };
    Map<dynamic, dynamic> l3 = /*@typeArgs=dynamic, dynamic*/ {3: 3};
    Map<dynamic, dynamic> l4 = /*@typeArgs=dynamic, dynamic*/ {
      3: "hello",
      "hello": 3
    };
  }
  {
    Map<dynamic, String> l0 = /*@typeArgs=dynamic, String*/ {};
    Map<dynamic, String> l1 = /*@typeArgs=dynamic, String*/ {3: "hello"};
    Map<dynamic, String> l2 = /*@typeArgs=dynamic, String*/ {"hello": "hello"};
    Map<dynamic, String> l3 = /*@typeArgs=dynamic, String*/ {
      3: /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/ 3
    };
    Map<dynamic, String> l4 = /*@typeArgs=dynamic, String*/ {
      3: "hello",
      "hello": /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/ 3
    };
  }
  {
    Map<int, dynamic> l0 = /*@typeArgs=int, dynamic*/ {};
    Map<int, dynamic> l1 = /*@typeArgs=int, dynamic*/ {3: "hello"};
    Map<int, dynamic> l2 = /*@typeArgs=int, dynamic*/ {
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/ "hello": "hello"
    };
    Map<int, dynamic> l3 = /*@typeArgs=int, dynamic*/ {3: 3};
    Map<int, dynamic> l4 = /*@typeArgs=int, dynamic*/ {
      3: "hello",
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/ "hello": 3
    };
  }
  {
    Map<int, String> l0 = /*error:INVALID_CAST_LITERAL_MAP*/ <num, dynamic>{};
    Map<int, String> l1 = /*error:INVALID_CAST_LITERAL_MAP*/ <num, dynamic>{
      3: "hello"
    };
    Map<int, String> l3 = /*error:INVALID_CAST_LITERAL_MAP*/ <num, dynamic>{
      3: 3
    };
  }
  {
    const Map<int, String> l0 = /*@typeArgs=int, String*/ const {};
    const Map<int, String> l1 = /*@typeArgs=int, String*/ const {3: "hello"};
    const Map<int, String> l2 = /*@typeArgs=int, String*/ const {
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE,error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/ "hello":
          "hello"
    };
    const Map<int, String> l3 = /*@typeArgs=int, String*/ const {
      3: /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE,error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/ 3
    };
    const Map<int, String> l4 = /*@typeArgs=int, String*/ const {
      3: "hello",
      /*error:MAP_KEY_TYPE_NOT_ASSIGNABLE,error:MAP_KEY_TYPE_NOT_ASSIGNABLE*/ "hello":
          /*error:MAP_VALUE_TYPE_NOT_ASSIGNABLE,error:MAP_VALUE_TYPE_NOT_ASSIGNABLE*/ 3
    };
  }
}

main() {}
