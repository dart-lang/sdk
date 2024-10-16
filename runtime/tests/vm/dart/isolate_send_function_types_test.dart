// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
import 'dart:async';
import 'dart:isolate';

import 'package:expect/async_helper.dart' show asyncEnd, asyncStart;

class A<T> {}

main(args) async {
  asyncStart();
  final x = A<void Function()>();

  await Isolate.spawn(isolate, x);

  Future<void> genericFunc<T>() async {
    final y = A<void Function(T)>();
    await Isolate.spawn(isolate, y);
  }

  await genericFunc<int>();
  asyncEnd();
}

void isolate(A foo) async {
  print('Tick: ${foo}');
}
