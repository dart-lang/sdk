// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value([x]) {}
  dynamic noSuchMethod(/*@topType=Invocation*/ invocation);
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function onError}) => null;
}

Future f;
// Instantiates Future<int>
Future<int> t1 = f. /*@typeArgs=int*/ /*@target=Future::then*/ then(
    /*@returnType=Future<int>*/ (/*@type=dynamic*/ _) =>
        new /*@typeArgs=int*/ Future.value('hi'));

// Instantiates List<int>
Future<List<int>> t2 = f. /*@typeArgs=List<int>*/ /*@target=Future::then*/ then(
    /*@returnType=List<int>*/ (/*@type=dynamic*/ _) => /*@typeArgs=int*/ [3]);
Future<List<int>> g2() async {
  return /*@typeArgs=int*/ [3];
}

Future<List<int>> g3() async {
  return new /*@typeArgs=List<int>*/ Future.value(
      /*@typeArgs=int*/ [3]);
}

main() {}
