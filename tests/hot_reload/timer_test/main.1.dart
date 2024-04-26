// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';
import 'dart:async';

var counter = 0;

Future<void> main() async {
  final periodicTimerDone = Completer();

  Expect.equals(0, hotReloadGeneration);
  Expect.equals(0, counter++);
  Timer.periodic(Duration(milliseconds: 400), (timer) {
    // Runs in the final generation.
    Expect.equals(2, hotReloadGeneration);
    periodicTimerDone.complete();
    timer.cancel();
  });

  await Future.delayed(Duration(milliseconds: 20), () {
    Expect.equals(1, counter++);
  });

  Expect.equals(0, hotReloadGeneration);
  Expect.isFalse(periodicTimerDone.isCompleted);

  await hotReload();

  Expect.equals(1, hotReloadGeneration);
  Expect.equals(2, counter++);
  await Future.delayed(Duration(milliseconds: 20), () {
    Expect.equals(3, counter++);
  });
  Expect.equals(1, hotReloadGeneration);
  Expect.isFalse(periodicTimerDone.isCompleted);

  await hotReload();

  Expect.isFalse(periodicTimerDone.isCompleted);
  Expect.equals(2, hotReloadGeneration);
  Expect.equals(4, counter++);

  await periodicTimerDone.future;
}
/** DIFF **/
/*
*/
