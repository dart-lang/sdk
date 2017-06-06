// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

Future<int> make(int x) => (new /*@typeArgs=int*/ Future(
    /*@returnType=int*/ () => x));

main() {
  Iterable<Future<int>> list = <int>[1, 2, 3]
      . /*@typeArgs=Future<int>*/ /*@target=Iterable::map*/ map(make);
  Future<List<int>> results = Future. /*@typeArgs=int*/ wait(list);
  Future<String> results2 =
      results. /*@typeArgs=String*/ /*@target=Future::then*/ then(
          /*@returnType=FutureOr<String>*/ (List<int> list) => list
              . /*@typeArgs=FutureOr<String>*/ /*@target=Iterable::fold*/ fold(
                  '',
                  /*@returnType=FutureOr<String>*/ (/*@type=FutureOr<String>*/ x,
                          /*@type=int*/ y) => /*info:DYNAMIC_CAST,info:DYNAMIC_INVOKE*/ x /*error:UNDEFINED_OPERATOR*/ +
                      y. /*@target=Object::toString*/ toString()));

  Future<String> results3 =
      results. /*@typeArgs=String*/ /*@target=Future::then*/ then(
          /*@returnType=FutureOr<String>*/ (List<int> list) => list
              . /*@typeArgs=FutureOr<String>*/ /*@target=Iterable::fold*/ fold(
                  '',
                  /*info:INFERRED_TYPE_CLOSURE,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ /*@returnType=String*/ (String
                              x,
                          /*@type=int*/ y) =>
                      x /*@target=String::+*/ +
                      y. /*@target=Object::toString*/ toString()));

  Future<String> results4 =
      results. /*@typeArgs=String*/ /*@target=Future::then*/ then(
          /*@returnType=String*/ (List<int> list) =>
              list. /*@target=Iterable::fold*/ fold<String>(
                  '',
                  /*@returnType=String*/ (/*@type=String*/ x,
                          /*@type=int*/ y) =>
                      x /*@target=String::+*/ +
                      y. /*@target=Object::toString*/ toString()));
}
