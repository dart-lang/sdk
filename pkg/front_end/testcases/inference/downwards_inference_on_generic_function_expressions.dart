// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void main() {
  {
    String f<S>(int x) => null;
    var /*@type=(int) -> String*/ v = f;
    v = /*@returnType=String*/ <T>(int x) => null;
    v = /*@returnType=String*/ <T>(int x) => "hello";
    v = /*error:INVALID_ASSIGNMENT*/ /*@returnType=String*/ <T>(String x) =>
        "hello";
    v = /*error:INVALID_ASSIGNMENT*/ /*@returnType=int*/ <T>(int x) => 3;
    v = /*@returnType=String*/ <T>(int x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ 3;
    };
  }
  {
    String f<S>(int x) => null;
    var /*@type=(int) -> String*/ v = f;
    v = /*@returnType=String*/ <T>(/*@type=int*/ x) => null;
    v = /*@returnType=String*/ <T>(/*@type=int*/ x) => "hello";
    v = /*info:INFERRED_TYPE_CLOSURE, error:INVALID_ASSIGNMENT*/ /*@returnType=int*/ <
            T>(/*@type=int*/ x) =>
        3;
    v = /*@returnType=String*/ <T>(/*@type=int*/ x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ 3;
    };
    v = /*@returnType=String*/ <T>(/*@type=int*/ x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ x;
    };
  }
  {
    List<String> f<S>(int x) => null;
    var /*@type=(int) -> List<String>*/ v = f;
    v = /*@returnType=List<String>*/ <T>(int x) => null;
    v = /*@returnType=List<String>*/ <T>(int x) => /*@typeArgs=String*/ [
          "hello"
        ];
    v = /*error:INVALID_ASSIGNMENT*/ /*@returnType=List<String>*/ <
        T>(String x) => /*@typeArgs=String*/ ["hello"];
    v = /*@returnType=List<String>*/ <T>(int x) => /*@typeArgs=String*/ [
          /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 3
        ];
    v = /*@returnType=List<String>*/ <T>(int x) {
      return /*@typeArgs=String*/ [
        /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 3
      ];
    };
  }
  {
    int int2int<S>(int x) => null;
    String int2String<T>(int x) => null;
    String string2String<T>(String x) => null;
    var /*@type=(int) -> int*/ x = int2int;
    x = /*@returnType=int*/ <T>(/*@type=int*/ x) => x;
    x = /*@returnType=int*/ <T>(/*@type=int*/ x) => x /*@target=num::+*/ + 1;
    var /*@type=(int) -> String*/ y = int2String;
    y = /*info:INFERRED_TYPE_CLOSURE, error:INVALID_ASSIGNMENT*/ /*@returnType=int*/ <
            T>(/*@type=int*/ x) =>
        x;
    y = /*@returnType=String*/ <
        T>(/*@type=int*/ x) => /*info:DYNAMIC_INVOKE, info:DYNAMIC_CAST*/ x.substring(3);
    var /*@type=(String) -> String*/ z = string2String;
    z = /*@returnType=String*/ <T>(/*@type=String*/ x) =>
        x. /*@target=String::substring*/ substring(3);
  }
}
