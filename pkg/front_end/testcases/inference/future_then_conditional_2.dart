// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation);
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function onError}) => null;
}

void test() {
  MyFuture<bool> f;
  Future<int> t1 = f. /*@typeArgs=int*/ /*@target=MyFuture::then*/ then(
      /*@returnType=Future<int>*/ (/*@type=bool*/ x) async =>
          x ? 2 : await new MyFuture<int>.value(3));
  Future<int> t2 = f. /*@typeArgs=int*/ /*@target=MyFuture::then*/ then(
      /*@returnType=Future<int>*/ (/*@type=bool*/ x) async {
    return /*info:DOWN_CAST_COMPOSITE*/ await x
        ? 2
        : new MyFuture<int>.value(3);
  });
  Future<int> t5 = f. /*@typeArgs=int*/ /*@target=MyFuture::then*/ then(
      /*info:INFERRED_TYPE_CLOSURE,error:INVALID_CAST_FUNCTION_EXPR*/
      /*@returnType=Object*/ (/*@type=bool*/ x) =>
          x ? 2 : new MyFuture<int>.value(3));
  Future<int> t6 = f. /*@typeArgs=int*/ /*@target=MyFuture::then*/ then(
      /*@returnType=FutureOr<int>*/ (/*@type=bool*/ x) {
    return /*info:DOWN_CAST_COMPOSITE*/ x ? 2 : new MyFuture<int>.value(3);
  });
}

main() {}
