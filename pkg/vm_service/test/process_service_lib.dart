// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;

import 'common/test_helper.dart';

Future setupProcesses() async {
  final dir = await io.Directory.systemTemp.createTemp('file_service');

  final args = [
    ...io.Platform.executableArguments,
    '--pause_isolates_on_start',
    io.Platform.script.toFilePath(),
  ];
  io.Process? process1;
  io.Process? process2;
  io.Process? process3;

  void closeDown() {
    if (process1 != null) {
      process1!.kill();
    }
    if (process2 != null) {
      process2!.kill();
    }
    if (process3 != null) {
      process3!.kill();
    }
    dir.deleteSync(recursive: true);
  }

  Future<ServiceExtensionResponse> cleanup(ignoredA, ignoredB) {
    closeDown();
    final result = jsonEncode({'type': 'foobar'});
    return Future.value(ServiceExtensionResponse.result(result));
  }

  Future<ServiceExtensionResponse> setup(ignoredA, ignoredB) async {
    try {
      process1 = await io.Process.start(io.Platform.resolvedExecutable, args);
      process2 = await io.Process.start(
        io.Platform.resolvedExecutable,
        args..add('foobar'),
      );
      final codeFilePath = '${dir.path}${io.Platform.pathSeparator}other_file';
      final codeFile = io.File(codeFilePath);
      await codeFile.writeAsString('''
          import "dart:io";

          Future<void> main([List<String> args = const <String>[]]) async {
            await stdin.drain();
          }
          ''');
      process3 = await io.Process.start(
        io.Platform.resolvedExecutable,
        [
          ...io.Platform.executableArguments,
          codeFilePath,
        ],
      );
    } catch (_) {
      closeDown();
      rethrow;
    }

    final result = jsonEncode({
      'type': 'foobar',
      'pids': [process1!.pid, process2!.pid, process3!.pid],
    });
    return Future.value(ServiceExtensionResponse.result(result));
  }

  Future<ServiceExtensionResponse> closeStdin(ignoredA, ignoredB) {
    process3!.stdin.close();
    return process3!.exitCode.then<ServiceExtensionResponse>((int exit) {
      final result = jsonEncode({'type': 'foobar'});
      return ServiceExtensionResponse.result(result);
    });
  }

  registerExtension('ext.dart.io.cleanup', cleanup);
  registerExtension('ext.dart.io.setup', setup);
  registerExtension('ext.dart.io.closeStdin', closeStdin);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: setupProcesses);
}
