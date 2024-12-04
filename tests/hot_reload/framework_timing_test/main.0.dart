// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

var x = 'Hello World';

Future<void> main() async {
  Expect.equals('Hello World', x);
  Expect.equals(0, hotRestartGeneration);

  scheduleMicrotask(() {
    Expect.equals(0, hotRestartGeneration);
  });
  Future<Null>.microtask(() {
    throw x;
  }).catchError((e, stackTrace) {
    Expect.equals("Hello World", e);
    Expect.equals(0, hotRestartGeneration);
  }).then((_) {
    Expect.equals(0, hotRestartGeneration);
  });
  Future.delayed(Duration(seconds: 5), () {
    throw Exception('Future from main.0.dart before hot restart. '
        'This should never run.');
  });

  await hotRestart();
}
