// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void main() {
  {
    String f<S>(int x) => null;
    var /*@type=<S extends Object>(int) -> String*/ v = f;
    v = <T> /*@returnType=String*/ (int x) => null;
    v = <T> /*@returnType=String*/ (int x) => "hello";
    v = /*error:INVALID_ASSIGNMENT*/ <T> /*@returnType=String*/ (String x) =>
        "hello";
    v = /*error:INVALID_ASSIGNMENT*/ <T> /*@returnType=int*/ (int x) => 3;
    v = <T> /*@returnType=String*/ (int x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ 3;
    };
  }
  {
    String f<S>(int x) => null;
    var /*@type=<S extends Object>(int) -> String*/ v = f;
    v = <T> /*@returnType=String*/ (/*@type=int*/ x) => null;
    v = <T> /*@returnType=String*/ (/*@type=int*/ x) => "hello";
    v = /*info:INFERRED_TYPE_CLOSURE, error:INVALID_ASSIGNMENT*/ <
            T> /*@returnType=int*/ (/*@type=int*/ x) =>
        3;
    v = <T> /*@returnType=String*/ (/*@type=int*/ x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ 3;
    };
    v = <T> /*@returnType=String*/ (/*@type=int*/ x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ x;
    };
  }
  {
    List<String> f<S>(int x) => null;
    var /*@type=<S extends Object>(int) -> List<String>*/ v = f;
    v = <T> /*@returnType=List<String>*/ (int x) => null;
    v = <T> /*@returnType=List<String>*/ (int x) => /*@typeArgs=String*/ [
          "hello"
        ];
    v = /*error:INVALID_ASSIGNMENT*/ <T> /*@returnType=List<String>*/ (String
        x) => /*@typeArgs=String*/ ["hello"];
    v = <T> /*@returnType=List<String>*/ (int x) => /*@typeArgs=String*/ [
          /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 3
        ];
    v = <T> /*@returnType=List<String>*/ (int x) {
      return /*@typeArgs=String*/ [
        /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 3
      ];
    };
  }
  {
    int int2int<S>(int x) => null;
    String int2String<T>(int x) => null;
    String string2String<T>(String x) => null;
    var /*@type=<S extends Object>(int) -> int*/ x = int2int;
    x = <T> /*@returnType=int*/ (/*@type=int*/ x) => x;
    x = <T> /*@returnType=int*/ (/*@type=int*/ x) => x /*@target=num::+*/ + 1;
    var /*@type=<T extends Object>(int) -> String*/ y = int2String;
    y = /*info:INFERRED_TYPE_CLOSURE, error:INVALID_ASSIGNMENT*/ <
            T> /*@returnType=int*/ (/*@type=int*/ x) =>
        x;
    y = <T> /*@returnType=String*/ (/*@type=int*/ x) => /*info:DYNAMIC_INVOKE, info:DYNAMIC_CAST*/ x
        .substring(3);
    var /*@type=<T extends Object>(String) -> String*/ z = string2String;
    z = <T> /*@returnType=String*/ (/*@type=String*/ x) =>
        x. /*@target=String::substring*/ substring(3);
  }
}
