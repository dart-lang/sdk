// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.16

// ignore_for_file: unused_local_variable

import 'dart:ffi';

class MyFinalizable implements Finalizable {}

int doSomething() => 3;

Iterable<int> useFinalizableSyncStar(Finalizable finalizable) sync* {
  // _in::reachabilityFence(finalizable);
  yield doSomething();
  final finalizable2 = MyFinalizable();
  // _in::reachabilityFence(finalizable);
  // _in::reachabilityFence(finalizable2);
  yield 5;
  final finalizable3 = MyFinalizable();
  // _in::reachabilityFence(finalizable);
  // _in::reachabilityFence(finalizable2);
  // _in::reachabilityFence(finalizable3);
  yield 10;
  // _in::reachabilityFence(finalizable);
  // _in::reachabilityFence(finalizable2);
  // _in::reachabilityFence(finalizable3);
}

void main() {
  final finalizable = MyFinalizable();
  for (final element in useFinalizableSyncStar(finalizable)) {
    print(element);
  }
}
