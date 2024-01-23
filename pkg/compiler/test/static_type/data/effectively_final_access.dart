// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  effectivelyFinalFunctionTyped();
  effectivelyFinalGenericFunctionTyped(null);
  effectivelyFinalDynamicallyTyped();
  effectivelyFinalPartiallyTyped();
}

effectivelyFinalFunctionTyped() {
  Function f = (int i) => /*int*/ i;
  /*int Function(int)*/ f. /*invoke: [int Function(int)]->int*/ call(0);
  (/*int Function(int)*/ f.call) /*invoke: [int Function(int)]->int*/ (0);
}

effectivelyFinalGenericFunctionTyped(T Function<T>(T)? g) {
  Function? f = /*T Function<T extends Object>(T)*/ g;
  /*T Function<T extends Object>(T)*/ f!
      . /*invoke: [T Function<T extends Object>(T)]->int*/ call<int>(0);
  (/*Function*/ f.call)
      .
      /*invoke: [Function]->dynamic*/
      call<int>(0);
}

effectivelyFinalDynamicallyTyped() {
  dynamic list = <int>[0];
  /*List<int>*/ list.first /*invoke: [int]->int*/ + 0;
  /*List<int>*/ list /*[List<int>]->int*/
          [0] /*invoke: [int]->int*/ +
      0;
  (/*List<int>*/ list.contains) /*invoke: [bool Function(Object)]->bool*/ (0);
  /*List<int>*/ list
      /*update: [List<int>]->void*/ /*[List<int>]->int*/
      [0] /*invoke: [int]->int*/ ++;
}

effectivelyFinalPartiallyTyped() {
  List list = <int>[0];
  /*List<int>*/ list.first /*invoke: [int]->int*/ + 0;
  /*List<int>*/ list /*[List<int>]->int*/
          [0] /*invoke: [int]->int*/ +
      0;
  (/*List<int>*/ list.contains) /*invoke: [bool Function(Object)]->bool*/ (0);
  /*List<int>*/ list
      /*update: [List<int>]->void*/ /*[List<int>]->int*/
      [0] /*invoke: [int]->int*/ ++;
}
