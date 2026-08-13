// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

void test() {
  {
    String f<S>(int x) => throw '';
    var v = f;
    v = <T>(int x) => throw '';
    v = <T>(int x) => "hello";
    v = /*error:INVALID_ASSIGNMENT*/ <T>(String x) => "hello";
    v = /*error:INVALID_ASSIGNMENT*/ <T>(int x) => 3;
    v = <T>(int x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ 3;
    };
  }
  {
    String f<S>(int x) => throw '';
    var v = f;
    v = <T>(x) => throw '';
    v = <T>(x) => "hello";
    v = /*info:INFERRED_TYPE_CLOSURE, error:INVALID_ASSIGNMENT*/ <T>(x) => 3;
    v = <T>(x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ 3;
    };
    v = <T>(x) {
      return /*error:RETURN_OF_INVALID_TYPE*/ x;
    };
  }
  {
    List<String> f<S>(int x) => throw '';
    var v = f;
    v = <T>(int x) => throw '';
    v = <T>(int x) => ["hello"];
    v = /*error:INVALID_ASSIGNMENT*/ <T>(String x) => ["hello"];
    v = <T>(int x) => [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 3];
    v = <T>(int x) {
      return [/*error:LIST_ELEMENT_TYPE_NOT_ASSIGNABLE*/ 3];
    };
  }
  {
    int int2int<S>(int x) => throw '';
    String int2String<T>(int x) => throw '';
    String string2String<T>(String x) => throw '';
    var x = int2int;
    x = <T>(x) => x;
    x = <T>(x) => x + 1;
    var y = int2String;
    y = /*info:INFERRED_TYPE_CLOSURE, error:INVALID_ASSIGNMENT*/ <T>(x) => x;
    y = <T>(x) => /*info:DYNAMIC_INVOKE, info:DYNAMIC_CAST*/ x.substring(3);
    var z = string2String;
    z = <T>(x) => x.substring(3);
  }
}

main() {}
