// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.16

// ignore_for_file: unused_local_variable

import 'dart:ffi';

Future<int> doSomething() async => 3;

class MyFinalizable implements Finalizable {
  Future<int> use() async {
    return doSomething();
  }

  Future<int> use2() async {
    return await doSomething();
  }

  Future<int> use3() {
    return doSomething();
  }
}

Future<int> useFinalizableAsync(Finalizable finalizable) async {
  await Future.sync(() => 6);
  final finalizable2 = MyFinalizable();
  await Future.sync(() => 5);
  final finalizable3 = MyFinalizable();
  await Future.sync(() => 4);
  return doSomething();
}

void main() async {
  final finalizable = MyFinalizable();
  final asyncResult = useFinalizableAsync(finalizable);
  print(await asyncResult);
}
