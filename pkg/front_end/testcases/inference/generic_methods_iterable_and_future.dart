// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

Future<int> make(int x) =>
    (/*@typeArgs=int*/ new Future(/*@returnType=int*/ () => x));

main() {
  Iterable<Future<int>> list = <int>[1, 2, 3].map(make);
  Future<List<int>> results = Future.wait(/*@promotedType=none*/ list);
  Future<String> results2 = /*@promotedType=none*/ results.then(
      /*@returnType=FutureOr<String>*/ (List<int> list) => list.fold(
          '',
          /*@returnType=FutureOr<String>*/ (/*@type=FutureOr<String>*/ x,
                  /*@type=int*/ y) => /*info:DYNAMIC_CAST,info:DYNAMIC_INVOKE*/ x /*error:UNDEFINED_OPERATOR*/ +
              y.toString()));

  Future<String> results3 = /*@promotedType=none*/ results.then(
      /*@returnType=FutureOr<String>*/ (List<int> list) => list.fold(
          '',
          /*info:INFERRED_TYPE_CLOSURE,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ /*@returnType=String*/ (String
                      x,
                  /*@type=int*/ y) =>
              x + y.toString()));

  Future<String> results4 = /*@promotedType=none*/ results.then(
      /*@returnType=String*/ (List<int> list) => list.fold<String>(
          '',
          /*@returnType=String*/ (/*@type=String*/ x, /*@type=int*/ y) =>
              x + y.toString()));
}
