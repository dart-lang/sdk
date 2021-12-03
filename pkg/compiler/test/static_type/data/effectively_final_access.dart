// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  effectivelyFinalFunctionTyped();
  effectivelyFinalGenericFunctionTyped(null);
  effectivelyFinalDynamicallyTyped();
  effectivelyFinalPartiallyTyped();
}

effectivelyFinalFunctionTyped() {
  Function f = (int i) => /*spec.int*/ i;
  /*spec.int Function(int)*/ f
      . /*spec.invoke: [int Function(int)]->int*/ call(0);
  (/*spec.int Function(int)*/ f
      .call) /*spec.invoke: [int Function(int)]->int*/ (0);
}

effectivelyFinalGenericFunctionTyped(T Function<T>(T) g) {
  Function f = /*spec.T Function<T extends Object>(T)*/ g;
  /*spec.T Function<T extends Object>(T)*/ f
      . /*spec.invoke: [T Function<T extends Object>(T)]->int*/ call<int>(0);
  (/*spec.T Function<T extends Object>(T)*/ f.call)
      .
      /*spec.invoke: [T Function<T extends Object>(T)]->int*/
      call<int>(0);
}

effectivelyFinalDynamicallyTyped() {
  dynamic list = <int>[0];
  /*spec.List<int>*/ list.first /*spec.invoke: [int]->int*/ + 0;
  /*spec.List<int>*/ list /*spec.[List<int>]->int*/
          [0] /*spec.invoke: [int]->int*/ +
      0;
  (/*spec.List<int>*/ list
      .contains) /*spec.invoke: [bool Function(Object)]->bool*/ (0);
  /*spec.List<int>*/ list
      /*spec.update: [List<int>]->void*/ /*spec.[List<int>]->int*/
      [0] /*spec.invoke: [int]->int*/ ++;
}

effectivelyFinalPartiallyTyped() {
  List list = <int>[0];
  /*spec.List<int>*/ list.first /*spec.invoke: [int]->int*/ + 0;
  /*spec.List<int>*/ list /*spec.[List<int>]->int*/
          [0] /*spec.invoke: [int]->int*/ +
      0;
  (/*spec.List<int>*/ list
      .contains) /*spec.invoke: [bool Function(Object)]->bool*/ (0);
  /*spec.List<int>*/ list
      /*spec.update: [List<int>]->void*/ /*spec.[List<int>]->int*/
      [0] /*spec.invoke: [int]->int*/ ++;
}
