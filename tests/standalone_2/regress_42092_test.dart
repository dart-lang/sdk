// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:expect/expect.dart';

Process process;
bool lastKill = false;

Future<void> sigint(int iterations) async {
  for (int i = 0; i < iterations; ++i) {
    if (i + 1 == iterations) {
      lastKill = true;
    }
    process.kill(ProcessSignal.sigint);
    // Yield to the event loop to allow for the signal to be sent.
    await Future.value(null);
  }
}

Future<void> main() async {
  process = await Process.start(
    Platform.resolvedExecutable,
    [
      Platform.script.resolve('regress_42092_script.dart').toString(),
    ],
  );
  final startCompleter = Completer<void>();
  StreamSubscription sub;
  sub = process.stdout.transform(Utf8Decoder()).listen((event) {
    if (event.contains('Waiting...')) {
      startCompleter.complete();
      sub.cancel();
    }
  });

  // Wait for target script to setup its signal handling.
  await startCompleter.future;

  final exitCompleter = Completer<void>();
  process.exitCode.then((code) {
    Expect.isTrue(lastKill);
    exitCompleter.complete();
  });
  await sigint(3);
  await exitCompleter.future;
}
