// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;

import 'package:observatory_2/service_io.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'test_helper.dart';

final dartJITBinary = path.join(path.dirname(io.Platform.resolvedExecutable),
    'dart' + path.extension(io.Platform.resolvedExecutable));

Future setupProcesses() async {
  final dir = await io.Directory.systemTemp.createTemp('file_service');

  final args = [
    ...io.Platform.executableArguments,
    '--pause_isolates_on_start',
    io.Platform.script.toFilePath(),
  ];
  io.Process process1;
  io.Process process2;
  io.Process process3;

  void closeDown() {
    if (process1 != null) {
      process1.kill();
    }
    if (process2 != null) {
      process2.kill();
    }
    if (process3 != null) {
      process3.kill();
    }
    dir.deleteSync(recursive: true);
  }

  Future<ServiceExtensionResponse> cleanup(ignored_a, ignored_b) {
    closeDown();
    final result = jsonEncode({'type': 'foobar'});
    return Future.value(ServiceExtensionResponse.result(result));
  }

  Future<ServiceExtensionResponse> setup(ignored_a, ignored_b) async {
    try {
      process1 = await io.Process.start(io.Platform.executable, args);
      process2 =
          await io.Process.start(io.Platform.executable, args..add('foobar'));
      final codeFilePath = dir.path + io.Platform.pathSeparator + "other_file";
      final codeFile = io.File(codeFilePath);
      await codeFile.writeAsString('''
          import "dart:io";

          void main() async {
            await stdin.drain();
          }
          ''');
      process3 = await io.Process.start(
          dartJITBinary, [...io.Platform.executableArguments, codeFilePath]);
    } catch (_) {
      closeDown();
      rethrow;
    }

    final result = jsonEncode({
      'type': 'foobar',
      'pids': [process1.pid, process2.pid, process3.pid]
    });
    return Future.value(ServiceExtensionResponse.result(result));
  }

  Future<ServiceExtensionResponse> closeStdin(ignored_a, ignored_b) {
    process3.stdin.close();
    return process3.exitCode.then<ServiceExtensionResponse>((int exit) {
      final result = jsonEncode({'type': 'foobar'});
      return ServiceExtensionResponse.result(result);
    });
  }

  registerExtension('ext.dart.io.cleanup', cleanup);
  registerExtension('ext.dart.io.setup', setup);
  registerExtension('ext.dart.io.closeStdin', closeStdin);
}

final processTests = <IsolateTest>[
  // Initial.
  (Isolate isolate) async {
    final setup = await isolate.invokeRpcNoUpgrade('ext.dart.io.setup', {});
    try {
      var all = await isolate
          .invokeRpcNoUpgrade('ext.dart.io.getSpawnedProcesses', {});
      expect(all['type'], equals('SpawnedProcessList'));

      expect(all['processes'].length, equals(3));

      final first = await isolate.invokeRpcNoUpgrade(
          'ext.dart.io.getSpawnedProcessById',
          {'id': all['processes'][0]['id']});
      expect(first['name'], io.Platform.executable);
      expect(first['pid'], equals(setup['pids'][0]));
      expect(first['arguments'].contains('foobar'), isFalse);
      expect(first['startedAt'], greaterThan(0));

      final second = await isolate.invokeRpcNoUpgrade(
          'ext.dart.io.getSpawnedProcessById',
          {'id': all['processes'][1]['id']});
      expect(second['name'], io.Platform.executable);
      expect(second['pid'], equals(setup['pids'][1]));
      expect(second['arguments'].contains('foobar'), isTrue);
      expect(second['pid'] != first['pid'], isTrue);
      expect(second['startedAt'], greaterThan(0));
      expect(second['startedAt'], greaterThanOrEqualTo(first['startedAt']));

      final third = await isolate.invokeRpcNoUpgrade(
          'ext.dart.io.getSpawnedProcessById',
          {'id': all['processes'][2]['id']});
      expect(third['name'], dartJITBinary);
      expect(third['pid'], equals(setup['pids'][2]));
      expect(third['pid'] != first['pid'], isTrue);
      expect(third['pid'] != second['pid'], isTrue);
      expect(third['startedAt'], greaterThanOrEqualTo(second['startedAt']));

      await isolate.invokeRpcNoUpgrade('ext.dart.io.closeStdin', {});
      all = await isolate
          .invokeRpcNoUpgrade('ext.dart.io.getSpawnedProcesses', {});
      expect(all['type'], equals('SpawnedProcessList'));
      expect(all['processes'].length, equals(2));
    } finally {
      await isolate.invokeRpcNoUpgrade('ext.dart.io.cleanup', {});
    }
  },
];

main(args) async =>
    runIsolateTests(args, processTests, testeeBefore: setupProcesses);
