// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dart_data_home/dart_data_home.dart';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const verboseSubprocesses = false;

final packageRoot = p.dirname(
  p.dirname(
    Isolate.resolvePackageUriSync(
      Uri.parse('package:dart_data_home/dart_data_home.dart'),
    )!.toFilePath(),
  ),
);

final testsDir = p.join(packageRoot, 'test');

// Note: on Windows in JIT mode we have dart.exe spawning dartvm.exe, and
// underlying pid files will be created using the pid of the dartvm.exe while
// process.pid gives us access to the process id of the dart.exe. To accomodate
// for this in tests we send underlying PID from child process to the parent
// over stdout.
typedef TestScriptProcess = ({Process process, int pid});

Future<TestScriptProcess> startTestScript(
  String processName,
  String packageName,
  String pidFileContent,
) async {
  final scriptPath = p.join(testsDir, 'common', 'test_script.dart');
  final process = await Process.start(Platform.resolvedExecutable, [
    scriptPath,
    packageName,
    pidFileContent,
  ]);

  final ready = Completer<int>();

  process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(
    (line) {
      if (verboseSubprocesses) {
        print('[$processName] $line');
      }
      if (line.startsWith('OK:')) {
        ready.complete(int.parse(line.split(':')[1]));
      }
    },
  );
  process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(
    (line) {
      if (verboseSubprocesses) {
        print('[$processName] $line');
      }
    },
  );

  return (process: process, pid: await ready.future);
}

Future<void> killProcess(TestScriptProcess p) async {
  p.process.kill();
  await p.process.exitCode;
  if (Platform.isWindows) {
    // On Windows in JIT mode we have dart.exe spawning dartvm.exe. Which
    // means dart.exe exiting does not imply that dartvm.exe has already
    // terminated as well. We don't have Dart API to wait for a specific
    // process by PID so just give it a second to terminate.
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync();
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // Ignore any exceptions.
    }
  });

  test('pid files', () async {
    ({Process process, int pid})? p1;
    ({Process process, int pid})? p2;

    try {
      p1 = await startTestScript(
        'p1',
        tempDir.path,
        'test_content_from_script_p1',
      );
      p2 = await startTestScript(
        'p2',
        tempDir.path,
        'test_content_from_script_p2',
      );

      // Both processes should be found by listPidFiles.
      expect(
        listPidFiles(tempDir.path),
        equals({
          p1.pid: 'test_content_from_script_p1',
          p2.pid: 'test_content_from_script_p2',
        }),
      );

      // Kill one process and check that only one process is now found.
      await killProcess(p1);
      expect(
        listPidFiles(tempDir.path),
        equals({p2.pid: 'test_content_from_script_p2'}),
      );

      // Kill the second process and check that no processes are found.
      await killProcess(p2);
      expect(listPidFiles(tempDir.path).isEmpty, isTrue);
    } finally {
      p1?.process.kill();
      p2?.process.kill();
    }
  });
}
