// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

Future setupProcesses() async {
  var dir = await io.Directory.systemTemp.createTemp('file_service');

  var args = ['--pause_isolates_on_start', io.Platform.script.toFilePath()];
  var process1;
  var process2;
  var process3;

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
    var result = json.encode({'type': 'foobar'});
    return new Future.value(new ServiceExtensionResponse.result(result));
  }

  Future<ServiceExtensionResponse> setup(ignored_a, ignored_b) async {
    try {
      process1 = await io.Process.start(io.Platform.executable, args);
      process2 =
          await io.Process.start(io.Platform.executable, args..add('foobar'));
      var codeFilePath = dir.path + io.Platform.pathSeparator + "other_file";
      var codeFile = new io.File(codeFilePath);
      await codeFile.writeAsString('''
          import "dart:io";

          void main() async {
            await stdin.drain();
          }
          ''');
      process3 = await io.Process.start(io.Platform.executable, [codeFilePath]);
    } catch (e) {
      closeDown();
      throw e;
    }

    var result = json.encode({
      'type': 'foobar',
      'pids': [process1.pid, process2.pid, process3.pid]
    });
    return new Future.value(new ServiceExtensionResponse.result(result));
  }

  Future<ServiceExtensionResponse> closeStdin(ignored_a, ignored_b) async {
    process3.stdin.close();
    var result = json.encode({'type': 'foobar'});
    var returnValue =
        new Future.value(new ServiceExtensionResponse.result(result));
    return process3.exitCode.then((int exit) => returnValue);
  }

  registerExtension('ext.dart.io.cleanup', cleanup);
  registerExtension('ext.dart.io.setup', setup);
  registerExtension('ext.dart.io.closeStdin', closeStdin);
}

var processTests = [
  // Initial.
  (Isolate isolate) async {
    var setup = await isolate.invokeRpcNoUpgrade('ext.dart.io.setup', {});
    try {
      var all =
          await isolate.invokeRpcNoUpgrade('ext.dart.io.getProcesses', {});
      expect(all['type'], equals('_startedprocesses'));

      expect(all['data'].length, equals(3));

      var first = await isolate.invokeRpcNoUpgrade(
          'ext.dart.io.getProcessById', {'id': all['data'][0]['id']});
      expect(first['name'], io.Platform.executable);
      expect(first['pid'], equals(setup['pids'][0]));
      expect(first['arguments'].contains('foobar'), isFalse);
      expect(first['startedAt'], greaterThan(0));

      var second = await isolate.invokeRpcNoUpgrade(
          'ext.dart.io.getProcessById', {'id': all['data'][1]['id']});
      expect(second['name'], io.Platform.executable);
      expect(second['pid'], equals(setup['pids'][1]));
      expect(second['arguments'].contains('foobar'), isTrue);
      expect(second['pid'] != first['pid'], isTrue);
      expect(second['startedAt'], greaterThan(0));
      expect(second['startedAt'], greaterThanOrEqualTo(first['startedAt']));

      var third = await isolate.invokeRpcNoUpgrade(
          'ext.dart.io.getProcessById', {'id': all['data'][2]['id']});
      expect(third['name'], io.Platform.executable);
      expect(third['pid'], equals(setup['pids'][2]));
      expect(third['pid'] != first['pid'], isTrue);
      expect(third['pid'] != second['pid'], isTrue);
      expect(third['startedAt'], greaterThanOrEqualTo(second['startedAt']));

      await isolate.invokeRpcNoUpgrade('ext.dart.io.closeStdin', {});
      all = await isolate.invokeRpcNoUpgrade('ext.dart.io.getProcesses', {});
      expect(all['type'], equals('_startedprocesses'));
      expect(all['data'].length, equals(2));
    } finally {
      await isolate.invokeRpcNoUpgrade('ext.dart.io.cleanup', {});
    }
  },
];

main(args) async =>
    runIsolateTests(args, processTests, testeeBefore: setupProcesses);
