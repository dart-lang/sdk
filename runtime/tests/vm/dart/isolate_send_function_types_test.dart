// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
import 'dart:async';
import 'dart:isolate';

import 'package:expect/expect.dart';

class A<T> {}

main(args) async {
  final x = A<void Function()>();

  {
    final caughtErrorCompleter = Completer<String>();
    await runZonedGuarded(() {
      Isolate.spawn(isolate, x);
    }, (e, s) {
      caughtErrorCompleter.complete(e.toString());
    });
    Expect.equals(
        await caughtErrorCompleter.future,
        "Invalid argument(s): Illegal argument in isolate message : "
        "(function types are not supported yet)");
  }

  Future<void> genericFunc<T>() async {
    final y = A<void Function(T)>();
    final caughtErrorCompleter = Completer<String>();
    await runZoned(() {
      Isolate.spawn(isolate, y);
    }, onError: (e) {
      caughtErrorCompleter.complete(e.toString());
    });
    Expect.equals(
        await caughtErrorCompleter.future,
        "Invalid argument(s): Illegal argument in isolate message : "
        "(function types are not supported yet)");
  }

  await genericFunc<int>();
}

void isolate(A foo) async {
  print('Tick: ${foo}');
}
