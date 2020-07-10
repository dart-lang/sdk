// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that using spawnUri to spawn an isolate from app-jit snapshot works.

import 'dart:isolate';

import 'package:expect/expect.dart';

int computation(int n) =>
    List.generate(n, (i) => i == 0 ? 1 : 0).fold(0, (a, b) => a + b);

Future<void> main(List<String> args, [dynamic sendPort]) async {
  final isTraining = args.contains('--train');

  var result = 0;
  for (var i = 0; i < 1000; i++) {
    result += computation(i);
  }
  Expect.equals(999, result);
  if (isTraining) {
    print('OK(Trained)');
  } else {
    (sendPort as SendPort).send('OK(Run)');
  }
}
