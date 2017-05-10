// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

Future<int> make(int x) => (new /*@typeArgs=int*/ Future(
    /*@returnType=int*/ () => /*@promotedType=none*/ x));

main() {
  Iterable<Future<int>> list =
      <int>[1, 2, 3]. /*@typeArgs=Future<int>*/ /*@target=List::map*/ map(make);
  Future<List<int>> results =
      Future. /*@typeArgs=int*/ /*@target=Future::wait*/ wait(
          /*@promotedType=none*/ list);
  Future<String> results2 = /*@promotedType=none*/ results
      . /*@typeArgs=String*/ /*@target=Future::then*/ then(
          /*@returnType=FutureOr<String>*/ (List<int> list) => /*@promotedType=none*/ list
              . /*@typeArgs=FutureOr<String>*/ /*@target=List::fold*/ fold(
                  '',
                  /*@returnType=FutureOr<String>*/ (/*@type=FutureOr<String>*/ x,
                          /*@type=int*/ y) => /*info:DYNAMIC_CAST,info:DYNAMIC_INVOKE*/ /*@promotedType=none*/ x /*error:UNDEFINED_OPERATOR*/ +
                      /*@promotedType=none*/ y
                          . /*@target=Object::toString*/ toString()));

  Future<String> results3 = /*@promotedType=none*/ results
      . /*@typeArgs=String*/ /*@target=Future::then*/ then(
          /*@returnType=FutureOr<String>*/ (List<int> list) => /*@promotedType=none*/ list
              . /*@typeArgs=FutureOr<String>*/ /*@target=List::fold*/ fold(
                  '',
                  /*info:INFERRED_TYPE_CLOSURE,error:ARGUMENT_TYPE_NOT_ASSIGNABLE*/ /*@returnType=String*/ (String
                              x,
                          /*@type=int*/ y) =>
                      /*@promotedType=none*/ x /*@target=String::+*/ + /*@promotedType=none*/ y
                          . /*@target=Object::toString*/ toString()));

  Future<String> results4 = /*@promotedType=none*/ results
      . /*@typeArgs=String*/ /*@target=Future::then*/ then(
          /*@returnType=String*/ (List<int>
              list) => /*@promotedType=none*/ list. /*@target=List::fold*/ fold<
                  String>(
              '',
              /*@returnType=String*/ (/*@type=String*/ x,
                      /*@type=int*/ y) =>
                  /*@promotedType=none*/ x /*@target=String::+*/ + /*@promotedType=none*/ y
                      . /*@target=Object::toString*/ toString()));
}
