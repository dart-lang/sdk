// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:dartdev/src/commands/dart_mcp_server.dart';
import 'package:dartdev/src/sdk.dart';
import 'package:test/test.dart';

void main() {
  group('DartMCPServerCommand', () {
    late FakeRunner runner;
    late DartMCPServerCommand command;

    setUp(() {
      runner = FakeRunner();
      command = DartMCPServerCommand();
      runner.addCommand(command);
    });

    test('mcpServerSnapshot path is non-empty', () {
      expect(sdk.mcpServerSnapshot, isNotEmpty);
      expect(sdk.mcpServerSnapshot, contains('mcp_server.dart.snapshot'));
    });

    test(
      'delegates to `run dart_mcp_server@` when snapshot does not exist',
      () async {
        await runner.run(['mcp-server']);
        expect(runner.capturedArgs, equals(['run', 'dart_mcp_server@']));
      },
    );

    test('launches snapshot directly when snapshot exists', () async {
      final snapshotFile = File(sdk.mcpServerSnapshot);
      final shouldCreateDir = !snapshotFile.parent.existsSync();
      if (shouldCreateDir) {
        snapshotFile.parent.createSync(recursive: true);
      }
      final shouldCreateFile = !snapshotFile.existsSync();
      if (shouldCreateFile) {
        snapshotFile.writeAsStringSync('');
      }

      try {
        final result = await runner.run(['mcp-server']);
        expect(result, equals(0));
        // Should intercept and run via VmInteropHandler instead of falling back
        // to `run dart_mcp_server@`.
        expect(runner.capturedArgs, isNull);
      } finally {
        if (shouldCreateFile) {
          snapshotFile.deleteSync();
        }
      }
    });

    test('forwards command arguments', () async {
      await runner.run(['mcp-server', '--help', '--log-file', 'foo.log']);
      expect(
        runner.capturedArgs,
        equals(['run', 'dart_mcp_server@', '--help', '--log-file', 'foo.log']),
      );
    });

    test('strips experimental flag', () async {
      await runner.run(['mcp-server', '--experimental-mcp-server']);
      expect(runner.capturedArgs, equals(['run', 'dart_mcp_server@']));
    });

    test('strips experimental flag and keeps other args', () async {
      await runner.run(['mcp-server', '--experimental-mcp-server', 'foo']);
      expect(runner.capturedArgs, equals(['run', 'dart_mcp_server@', 'foo']));
    });

    test('forwards global arguments', () async {
      runner.argParser.addFlag('global-flag', negatable: false);
      await runner.run(['--global-flag', 'mcp-server']);
      expect(
        runner.capturedArgs,
        equals(['--global-flag', 'run', 'dart_mcp_server@']),
      );
    });
  });
}

class FakeRunner extends CommandRunner<int> {
  List<String>? capturedArgs;
  bool isFirstCall = true;

  FakeRunner() : super('dart', 'dart command runner');

  @override
  Future<int?> run(Iterable<String> args) async {
    if (isFirstCall) {
      isFirstCall = false;
      return await super.run(args);
    } else {
      capturedArgs = args.toList();
      return 0;
    }
  }
}
