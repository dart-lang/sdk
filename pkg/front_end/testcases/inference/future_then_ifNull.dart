// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(/*@topType=Invocation*/ invocation);
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function onError}) => null;
}

void test() {
  MyFuture<int> f;
  Future<int> t1 = f. /*@typeArgs=int*/ /*@target=MyFuture::then*/ then(
      /*@returnType=Future<int>*/ (/*@type=int*/ x) async =>
          x ?? await new Future<int>.value(3));
  Future<int> t2 = f. /*@typeArgs=int*/ /*@target=MyFuture::then*/ then(
      /*@returnType=Future<int>*/ (/*@type=int*/ x) async {
    return /*info:DOWN_CAST_COMPOSITE*/ await x ?? new Future<int>.value(3);
  });
  Future<int> t5 = f. /*@typeArgs=int*/ /*@target=MyFuture::then*/ then(
      /*error:INVALID_CAST_FUNCTION_EXPR*/
      /*@returnType=Object*/ (/*@type=int*/ x) =>
          x ?? new Future<int>.value(3));
  Future<int> t6 = f. /*@typeArgs=int*/ /*@target=MyFuture::then*/ then(
      /*@returnType=FutureOr<int>*/ (/*@type=int*/ x) {
    return /*info:DOWN_CAST_COMPOSITE*/ x ?? new Future<int>.value(3);
  });
}

main() {}
