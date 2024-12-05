// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

// Regression test for https://github.com/dart-lang/sdk/issues/56087

void main() {
  late final Process? process;

  tearDown(() {
    process?.kill();
  });

  test('Enabling the VM service with dart on PATH spawns DDS', () async {
    final script = path.join(
      path.dirname(Platform.script.toString()),
      'control_web_server_starts_dds_test.dart',
    );
    process = await Process.start(
      'dart',
      [script],
      environment: {'PATH': path.dirname(Platform.resolvedExecutable)},
    );

    final completer = Completer<void>();
    late final StreamSubscription<String>? stdoutSub;
    late final StreamSubscription<String>? stderrSub;
    stdoutSub = process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((event) {
      if (event == 'VM service started') {
        stdoutSub!.cancel();
        stderrSub?.cancel();
        completer.complete();
      }
    });

    stderrSub = process!.stderr.transform(utf8.decoder).listen((_) {
      stdoutSub!.cancel();
      stderrSub!.cancel();
      completer.completeError(
        'Unexpected output on stderr! DDS likely failed to start',
      );
    });

    await completer.future;
  });
}
