// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=signal_test_script.dart
// OtherResources=signals_test_script.dart
// Environment=TSAN_OPTIONS=report_thread_leaks=0

import "dart:io";
import "dart:convert";

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

testSignals(
  int usr1Expect,
  int usr2Expect, [
  int? usr1Send,
  int? usr2Send,
  bool shouldFail = false,
]) async {
  if (usr1Send == null) usr1Send = usr1Expect;
  if (usr2Send == null) usr2Send = usr2Expect;
  var process = await Process.start(
    Platform.executable,
    []
      ..addAll(Platform.executableArguments)
      ..add('--verbosity=warning')
      ..addAll([
        Platform.script.resolve('signals_test_script.dart').toFilePath(),
        usr1Expect.toString(),
        usr2Expect.toString(),
      ]),
  );
  process.stdin.close();
  var drain = process.stderr.drain();
  int v = 0;
  process.stdout.listen((out) {
    // Send as many signals as 'ready\n' received on stdout
    int count = out.where((c) => c == '\n'.codeUnitAt(0)).length;
    for (int i = 0; i < count; i++) {
      if (v < usr1Send!) {
        process.kill(ProcessSignal.sigusr1);
      } else if (v < usr1Send + usr2Send!) {
        process.kill(ProcessSignal.sigusr2);
      }
      v++;
    }
  });
  var exitCode = await process.exitCode;
  Expect.equals(shouldFail, exitCode != 0);
  await drain;
}

testSignal(ProcessSignal signal) async {
  var process = await Process.start(
    Platform.executable,
    []
      ..addAll(Platform.executableArguments)
      ..add('--verbosity=warning')
      ..addAll([
        Platform.script.resolve('signal_test_script.dart').toFilePath(),
        signal.toString(),
      ]),
  );
  process.stdin.close();
  var drain = process.stderr.drain();

  var output = "";
  process.stdout
      .transform(utf8.decoder)
      .listen(
        (str) {
          output += str;
          if (output == 'ready\n') {
            process.kill(signal);
          }
        },
        onDone: () {
          Expect.equals('ready\n$signal\n', output);
        },
      );
  var exitCode = await process.exitCode;
  Expect.equals(0, exitCode);
  await drain;
}

testMultipleSignals(List<ProcessSignal> signals) async {
  for (var signal in signals) {
    var process = await Process.start(
      Platform.executable,
      []
        ..addAll(Platform.executableArguments)
        ..add('--verbosity=warning')
        ..add(Platform.script.resolve('signal_test_script.dart').toFilePath())
        ..addAll(signals.map((s) => s.toString())),
    );
    process.stdin.close();
    var drain = process.stderr.drain();

    var output = "";
    process.stdout
        .transform(utf8.decoder)
        .listen(
          (str) {
            output += str;
            if (output == 'ready\n') {
              process.kill(signal);
            }
          },
          onDone: () {
            Expect.equals('ready\n$signal\n', output);
          },
        );
    var exitCode = await process.exitCode;
    Expect.equals(0, exitCode);
    await drain;
  }
}

void testListenCancel() {
  for (int i = 0; i < 10; i++) {
    ProcessSignal.sigint.watch().listen(null).cancel();
  }
}

main() async {
  testListenCancel();
  if (Platform.isWindows) return;

  asyncStart();
  await testSignals(0, 0);
  await testSignals(1, 0);
  await testSignals(0, 1);
  await testSignals(1, 1);
  await testSignals(10, 10);
  await testSignals(10, 1);
  await testSignals(1, 10);
  await testSignals(1, 0, 0, 1, true);
  await testSignals(0, 1, 1, 0, true);

  await testSignal(ProcessSignal.sighup);
  await testSignal(ProcessSignal.sigint);
  await testSignal(ProcessSignal.sigterm);
  await testSignal(ProcessSignal.sigusr1);
  await testSignal(ProcessSignal.sigusr2);
  await testSignal(ProcessSignal.sigwinch);

  await testMultipleSignals([
    ProcessSignal.sighup,
    ProcessSignal.sigint,
    ProcessSignal.sigterm,
    ProcessSignal.sigusr1,
    ProcessSignal.sigusr2,
    ProcessSignal.sigwinch,
  ]);
  asyncEnd();
}
