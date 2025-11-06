// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

typedef T Function2<S, T>(S x);

void test() {
  {
    Function2<int, String> l0 = (int x) => throw '';
    Function2<int, String> l1 = (int x) => "hello";
    Function2<int, String> l2 = /*error:INVALID_ASSIGNMENT*/ (String x) =>
        "hello";
    Function2<int, String> l3 = /*error:INVALID_ASSIGNMENT*/ (int x) => 3;
    Function2<int, String> l4 = (int x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ 3;
    };
  }
  {
    Function2<int, String> l0 = (x) => throw '';
    Function2<int, String> l1 = (x) => "hello";
    Function2<int, String>
    l2 = /*info:INFERRED_TYPE_CLOSURE, error:INVALID_ASSIGNMENT*/ (x) => 3;
    Function2<int, String> l3 = (x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ 3;
    };
    Function2<int, String> l4 = (x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ x;
    };
  }
  {
    Function2<int, List<String>> l0 = (int x) => throw '';
    Function2<int, List<String>> l1 = (int x) => ["hello"];
    Function2<int, List<String>> l2 = /*error:INVALID_ASSIGNMENT*/ (String x) =>
        ["hello"];
    Function2<int, List<String>> l3 = (int x) => [
      /*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 3,
    ];
    Function2<int, List<String>> l4 = (int x) {
      return [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 3];
    };
  }
  {
    Function2<int, int> l0 = (x) => x;
    Function2<int, int> l1 = (x) => x + 1;

    // error:INVALID_ASSIGNMENT
    Function2<int, String> l2 = (x) => x;
    Function2<int, String> l3 =
        (x) => /*info:DYNAMIC_CAST, info:DYNAMIC_INVOKE*/ x.substring(3);
    Function2<String, String> l4 = (x) => x.substring(3);
  }
}

main() {}
