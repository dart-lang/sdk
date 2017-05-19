// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

typedef T Function2<S, T>(S x);

void main() {
  {
    Function2<int, String> l0 = /*@returnType=String*/ (int x) => null;
    Function2<int, String> l1 = /*@returnType=String*/ (int x) => "hello";
    Function2<int, String>
        l2 = /*error:INVALID_ASSIGNMENT*/ /*@returnType=String*/ (String x) =>
            "hello";
    Function2<int, String>
        l3 = /*error:INVALID_ASSIGNMENT*/ /*@returnType=int*/ (int x) => 3;
    Function2<int, String> l4 = /*@returnType=String*/ (int x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ 3;
    };
  }
  {
    Function2<int, String> l0 = /*@returnType=String*/ (/*@type=int*/ x) =>
        null;
    Function2<int, String> l1 = /*@returnType=String*/ (/*@type=int*/ x) =>
        "hello";
    Function2<int, String>
        l2 = /*info:INFERRED_TYPE_CLOSURE, error:INVALID_ASSIGNMENT*/ /*@returnType=int*/ (/*@type=int*/ x) =>
            3;
    Function2<int, String> l3 = /*@returnType=String*/ (/*@type=int*/ x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ 3;
    };
    Function2<int, String> l4 = /*@returnType=String*/ (/*@type=int*/ x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ x;
    };
  }
  {
    Function2<int, List<String>> l0 = /*@returnType=List<String>*/ (int x) =>
        null;
    Function2<int, List<String>> l1 = /*@returnType=List<String>*/ (int
        x) => /*@typeArgs=String*/ ["hello"];
    Function2<int, List<String>>
        l2 = /*error:INVALID_ASSIGNMENT*/ /*@returnType=List<String>*/ (String
            x) => /*@typeArgs=String*/ ["hello"];
    Function2<int, List<String>>
        l3 = /*@returnType=List<String>*/ (int x) => /*@typeArgs=String*/ [
              /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 3
            ];
    Function2<int, List<String>> l4 = /*@returnType=List<String>*/ (int x) {
      return /*@typeArgs=String*/ [
        /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 3
      ];
    };
  }
  {
    Function2<int, int> l0 = /*@returnType=int*/ (/*@type=int*/ x) => x;
    Function2<int, int> l1 = /*@returnType=int*/ (/*@type=int*/ x) =>
        x /*@target=num::+*/ + 1;
    Function2<int, String>
        l2 = /*error:INVALID_ASSIGNMENT*/ /*@returnType=int*/ (/*@type=int*/ x) =>
            x;
    Function2<int, String>
        l3 = /*@returnType=String*/ (/*@type=int*/ x) => /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/ x
            .substring(3);
    Function2<String, String>
        l4 = /*@returnType=String*/ (/*@type=String*/ x) =>
            x. /*@target=String::substring*/ substring(3);
  }
}
