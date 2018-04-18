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
  var /*@type=Future<double>*/ f =
      foo(). /*@typeArgs=double*/ /*@target=Future::then*/ then(
          /*@returnType=double*/ (/*@type=dynamic*/ _) => 2.3);
  Future<int> f2 = /*error:INVALID_ASSIGNMENT*/ f;

  // The unnecessary cast is to illustrate that we inferred <double> for
  // the generic type args, even though we had a return type context.
  Future<num> f3 = /*info:UNNECESSARY_CAST*/ foo()
          . /*@typeArgs=double*/ /*@target=Future::then*/ then(
              /*@returnType=double*/ (/*@type=dynamic*/ _) => 2.3)
      as Future<double>;
}

Future foo() => new Future<int>.value(1);

main() {}
