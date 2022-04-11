// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
T map<T>(T Function() f1, T Function() f2) => throw '';

id<T>(T t) => t;

Null foo() => null;

test() {
  /*@ typeArgs=Null */ map(
      /*@ returnType=Null */ () {}, /*@returnType=Never*/ () => throw "hello");
  /*@ typeArgs=Null */ map(
      /*@returnType=Never*/ () => throw "hello", /*@ returnType=Null */ () {});
  Null Function() f = /*@ returnType=Null */ () {};
  /*@ typeArgs=Null */ map(foo, /*@returnType=Never*/ () => throw "hello");
  /*@ typeArgs=Null */ map(/*@returnType=Never*/ () => throw "hello", foo);
  /*@ typeArgs=Null */ map(/*@ returnType=Null */ () {
    return null;
  }, /*@returnType=Never*/ () => throw "hello");

  /*@ typeArgs=Null */ map(/*@returnType=Never*/ () => throw "hello",
      /*@ returnType=Null */ () {
    return null;
  });
  /*@typeArgs=() -> Null*/ id(/*@ returnType=Null */ () {});
}

main() {}
