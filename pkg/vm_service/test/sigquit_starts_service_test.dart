// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void runTest(bool withDartDev) {
  test(
      'Displays service URI on SIGQUIT ${withDartDev ? '' : 'with --disable-dart-dev'}',
      () async {
    final process = await Process.start(Platform.resolvedExecutable, [
      if (!withDartDev) '--disable-dart-dev',
      Platform.script.resolve('sigquit_starts_service_script.dart').toString(),
    ]);

    final readyCompleter = Completer<void>();
    final completer = Completer<void>();
    late StreamSubscription sub;
    sub = process.stdout.transform(utf8.decoder).listen((e) async {
      if (e.contains('ready') && !readyCompleter.isCompleted) {
        readyCompleter.complete();
      } else if (e.contains('The Dart VM service is listening on')) {
        await sub.cancel();
        completer.complete();
      }
    });

    // Wait for the process to start.
    await readyCompleter.future;
    process.kill(ProcessSignal.sigquit);
    await completer.future;
    process.kill();
  }, skip: Platform.isWindows);
}

void main() {
  runTest(true);
  runTest(false);
}
