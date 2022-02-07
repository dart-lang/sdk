// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.16

// ignore_for_file: unused_local_variable

import 'dart:ffi';

class MyFinalizable implements Finalizable {}

int doSomething() => 3;

Stream<int> useFinalizableAsyncStar(Finalizable finalizable) async* {
  final finalizable2 = MyFinalizable();
  yield doSomething();
  final finalizable3 = MyFinalizable();
  await Future.sync(() => 3);
  final finalizable4 = MyFinalizable();
  if (DateTime.now().millisecondsSinceEpoch == 4) {
    return;
  }
  yield 5;
}

void main() async {
  final finalizable = MyFinalizable();
  final asyncStarResult = useFinalizableAsyncStar(finalizable);
  await for (final element in asyncStarResult) {
    print(element);
  }
}
