// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N null_closures`

import 'dart:async';
import 'dart:core';

class A extends B {
  A(int x);
}
class B extends A {}

//https://github.com/dart-lang/linter/issues/1414
void test_cycle() {
  new A(null);
}

void list_firstWhere() {
  // firstWhere has a _named_ closure argument.
  <int>[2, 4, 6].firstWhere((e) => e.isEven, orElse: null); // LINT
  <int>[2, 4, 6].firstWhere((e) => e.isEven, orElse: () => null); // OK
  <int>[2, 4, 6].where(null); // LINT
  <int>[2, 4, 6].where((e) => e.isEven); // OK
}

void iterable_singleWhere() {
  // singleWhere has a _named_ closure argument.
  <int>{2, 4, 6}.singleWhere((e) => e.isEven, orElse: null); // LINT
  <int>[2, 4, 6].singleWhere((e) => e.isEven, orElse: () => null); // OK
}

void map_putIfAbsent() {
  // putIfAbsent has a _required_ closure argument.
  var map = <int, int>{};
  map.putIfAbsent(7, null); // LINT
  map.putIfAbsent(7, () => null); // OK
}

void future_wait() {
  // Future.wait is a _static_ function with a _named_ argument.
  Future.wait([], cleanUp: null); // LINT
  Future.wait([], cleanUp: (_) => print('clean')); // OK
}

void list_generate() {
  // List.generate is a _constructor_ with a _positional_ argument.
  new List.generate(3, null); // LINT
  new List.generate(3, (_) => null); // OK
}

void map_otherMethods() {
  // These methods have nothing we are concerned with.
  new Map().keys; // OK
  new Map().addAll({}); // OK
}
