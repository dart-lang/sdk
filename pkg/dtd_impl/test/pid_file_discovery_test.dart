// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dart_data_home/dart_data_home.dart';
import 'package:dtd_impl/dtd.dart';
import 'package:dtd_impl/src/dtd_connection_info.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  DartToolingDaemon? dtd;
  late Directory tempDir;
  late Map<String, String> env;

  // In the CI environment, `dart test` executes in a temporary build directory,
  // meaning `Platform.script` does not reliably point to the local source tree.
  // We use `Isolate.resolvePackageUri` in `setUpAll` to dynamically find the
  // correct absolute path to `bin/dtd.dart` so test subprocesses do not crash.
  late String dtdScriptPath;

  Future<(Process process, String uri)> startDtdProcess() async {
    final process = await Process.start(Platform.resolvedExecutable, [
      'run',
      dtdScriptPath,
      '--port=0',
    ], environment: env);

    String? uri;
    process.stderr.transform(utf8.decoder).listen((error) {
      if (error.trim().isNotEmpty) {
        print('DTD stderr: $error');
      }
    });

    final uriRegex = RegExp(
      r'The Dart Tooling Daemon is listening on (ws://.*)',
    );
    await for (final line
        in process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.startsWith('The Dart Tooling Daemon is listening on')) {
        final match = uriRegex.firstMatch(line);
        if (match != null) {
          uri = match.group(1);
        }
      } else if (line.startsWith('Trusted Client Secret')) {
        break; // We have both the URI (printed first) and the secret.
      }
    }

    if (uri == null) {
      process.kill();
      throw StateError('Failed to start DTD process. No URI printed.');
    }

    final dataHome = getDartDataHome(dtdDirName, environment: env);
    final pidFile = File(p.join(dataHome, process.pid.toString()));

    // On Windows bots, file creation can take more than 1 second.
    // Increasing timeout iterations to 100 (5 seconds) to avoid flakiness (Issue #62872).
    for (var i = 0; i < 100; i++) {
      if (pidFile.existsSync()) break;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    return (process, uri);
  }

  // To prevent test flakiness when running `dart test` in parallel, we
  // isolate this test suite's `dart_data_home` directory. Other test files
  // (like `dtd_test.dart`) may spin up DTD instances that write to the
  // default system data directories. By spoofing the environment variables
  // (LOCALAPPDATA, HOME, XDG_DATA_HOME), we ensure this suite only sees its
  // own PID files in a clean, isolated temporary directory.
  setUpAll(() async {
    final packageUri = await Isolate.resolvePackageUri(
      Uri.parse('package:dtd_impl/'),
    );
    dtdScriptPath = p.normalize(
      p.join(packageUri!.toFilePath(), '../bin/dtd.dart'),
    );
    tempDir = Directory.systemTemp.createTempSync('dtd_list_test_');
    env = Map<String, String>.from(Platform.environment);
    if (Platform.isWindows) {
      env['LOCALAPPDATA'] = tempDir.path;
      env['APPDATA'] = tempDir.path;
    } else if (Platform.isMacOS) {
      env['HOME'] = tempDir.path;
    } else {
      env['XDG_DATA_HOME'] = tempDir.path;
      env['HOME'] = tempDir.path;
    }
  });

  setUp(() {
    DartToolingDaemon.environmentOverride = env;
  });

  tearDown(() async {
    await dtd?.close();
    dtd = null;
    DartToolingDaemon.environmentOverride = null;

    final String dataHome = getDartDataHome(dtdDirName, environment: env);
    try {
      final dir = Directory(dataHome);
      if (dir.existsSync()) {
        for (final entity in dir.listSync()) {
          entity.deleteSync(recursive: true);
        }
      }
    } catch (_) {}
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('PID File Discovery', () {
    test('broadcasts connection info via pid file', () async {
      final (process, uri) = await startDtdProcess();

      final String dataHome = getDartDataHome(dtdDirName, environment: env);
      expect(dataHome, isNotEmpty);

      final processPid = process.pid;
      final file = File(p.join(dataHome, processPid.toString()));
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, Object?>;
      final info = DTDConnectionInfo.fromJson(json);

      expect(info.wsUri, uri);
      expect(info.pid, processPid);
      expect(info.dartVersion, Platform.version);
      expect(info.workspaceRoot, Directory.current.path);

      process.kill();
      expect(await process.exitCode, isNot(0));
    });

    test('connection info contains correct workspaceRoot', () async {
      final (process, _) = await startDtdProcess();

      final String dataHome = getDartDataHome(dtdDirName, environment: env);
      final file = File(p.join(dataHome, process.pid.toString()));
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, Object?>;
      final info = DTDConnectionInfo.fromJson(json);

      // Verify that workspaceRoot matches the current working directory of the process.
      expect(info.workspaceRoot, Directory.current.path);

      process.kill();
      expect(await process.exitCode, isNot(0));
    });

    test('list cleans up stale pid files', () async {
      final String dataHome = getDartDataHome(dtdDirName, environment: env);
      final garbageFile = File(p.join(dataHome, '999999'));

      // Even valid JSON should be cleaned up if the process is no longer active.
      garbageFile.writeAsStringSync(
        jsonEncode(<String, Object?>{
          'wsUri': 'ws://127.0.0.1:0',
          'epoch': 123456789,
          'pid': 999999,
          'dartVersion': '3.0.0',
          'workspaceRoot': '/test',
        }),
      );

      // Trigger the list command
      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        dtdScriptPath,
        '--list',
      ], environment: env);

      // It shouldn't crash, instead saying 0 instances
      expect(result.stdout.toString(), contains(noInstancesMessage));
      expect(result.stderr.toString(), isEmpty);

      // And it should have deleted the stale file.
      expect(garbageFile.existsSync(), isFalse);
    });

    test('list prints correct number of instances', () async {
      // 0 instances initially.
      var result = await Process.run(Platform.resolvedExecutable, [
        'run',
        dtdScriptPath,
        '--list',
      ], environment: env);
      expect(result.stdout.toString(), contains(noInstancesMessage));

      // 1 instance.
      final (dtd1, _) = await startDtdProcess();
      result = await Process.run(Platform.resolvedExecutable, [
        'run',
        dtdScriptPath,
        '--list',
      ], environment: env);
      expect(
        result.stdout.toString(),
        contains('Found 1 Dart Tooling Daemon instance(s):'),
      );

      // 2 instances.
      final (dtd2, _) = await startDtdProcess();
      result = await Process.run(Platform.resolvedExecutable, [
        'run',
        dtdScriptPath,
        '--list',
      ], environment: env);
      expect(
        result.stdout.toString(),
        contains('Found 2 Dart Tooling Daemon instance(s):'),
      );

      dtd1.kill();
      expect(await dtd1.exitCode, isNot(0));

      dtd2.kill();
      expect(await dtd2.exitCode, isNot(0));
    });

    test('list --machine prints JSON list of instances', () async {
      // 0 instances initially.
      var result = await Process.run(Platform.resolvedExecutable, [
        'run',
        dtdScriptPath,
        '--list',
        '--machine',
      ], environment: env);
      var json = jsonDecode(result.stdout.toString()) as List;
      expect(json, isEmpty);

      // 1 instance.
      final (dtd1, _) = await startDtdProcess();
      result = await Process.run(Platform.resolvedExecutable, [
        'run',
        dtdScriptPath,
        '--list',
        '--machine',
      ], environment: env);
      json = jsonDecode(result.stdout.toString()) as List;
      expect(json.length, 1);

      // 2 instances.
      final (dtd2, _) = await startDtdProcess();
      result = await Process.run(Platform.resolvedExecutable, [
        'run',
        dtdScriptPath,
        '--list',
        '--machine',
      ], environment: env);
      json = jsonDecode(result.stdout.toString()) as List;
      expect(json.length, 2);

      dtd1.kill();
      expect(await dtd1.exitCode, isNot(0));
      dtd2.kill();
      expect(await dtd2.exitCode, isNot(0));
    });
  });
}
