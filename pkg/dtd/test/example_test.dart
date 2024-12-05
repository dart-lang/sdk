// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dtd/dtd.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  late ToolingDaemonTestProcess toolingDaemonProcess;

  setUp(() async {
    toolingDaemonProcess = ToolingDaemonTestProcess();
    await toolingDaemonProcess.start();
  });

  tearDown(() async {
    toolingDaemonProcess.kill();
  });

  test('stream example', () async {
    final receiveACompleter = Completer<void>();
    final receiveBCompleter = Completer<void>();

    final streamProcess = await Process.start(
      Platform.resolvedExecutable,
      [
        'run',
        Platform.script
            .resolve('../example/dtd_stream_example.dart')
            .toString(),
        toolingDaemonProcess.uri.toString(),
      ],
    );
    final lines = <String>[];
    streamProcess.handle(
      stdoutLines: (line) {
        stdout.write('streamProcess stdout: $line');
        lines.add(line);
        final json = jsonDecode(line) as Map<String, Object?>;
        if (json['step'] == 'Event A received') {
          receiveACompleter.complete();
        } else if (json['step'] == 'Event B received') {
          receiveBCompleter.complete();
        }
      },
      stderrLines: (line) => stderr.write('streamProcess stderr: $line'),
    );
    await streamProcess.exitCode;

    expect(
      lines,
      containsAll([
        '{"step":"Event A received","event":{"event":1}}',
        '{"step":"Event B received","event":{"event":1}}',
      ]),
    );
  });

  test('service example', () async {
    final serviceExampleProcess = await Process.start(
      Platform.resolvedExecutable,
      [
        'run',
        Platform.script
            .resolve('../example/dtd_service_example.dart')
            .toString(),
        toolingDaemonProcess.uri.toString(),
      ],
    );

    final stdoutMessages = <Map<String, Object?>>[];
    serviceExampleProcess.handle(
      stdoutLines: (line) {
        stdout.write('serviceExample stdout: $line');
        stdoutMessages.add(jsonDecode(line) as Map<String, Object?>);
      },
      stderrLines: (line) => stderr.write('serviceExample stderr: $line'),
    );

    await serviceExampleProcess.exitCode;
    expect(
      stdoutMessages,
      containsAll([
        {
          'stream': 'Service',
          'kind': 'ServiceRegistered',
          'data': {
            'service': 'ExampleServer',
            'method': 'getServerState',
            'capabilities': {'supportsNewExamples': true},
          },
        },
        {
          'type': 'ExampleStateResponse',
          'status': 'The server is running',
          'uptime': const Duration(minutes: 45).inMilliseconds,
        },
        {
          'stream': 'Service',
          'kind': 'ServiceUnregistered',
          'data': {
            'service': 'ExampleServer',
            'method': 'getServerState',
          },
        },
      ]),
    );
  });

  test('file system example', () async {
    final readCompleter = Completer<void>();
    final listDirCompleter = Completer<void>();

    final tmpDirectory = await Directory.systemTemp.createTemp();
    DartToolingDaemon? client;
    try {
      client = await DartToolingDaemon.connect(
        toolingDaemonProcess.uri,
      );
      await client.setIDEWorkspaceRoots(
        toolingDaemonProcess.trustedSecret!,
        [tmpDirectory.uri],
      );

      final fileSystemServiceExampleProcess = await Process.start(
        Platform.resolvedExecutable,
        [
          'run',
          Platform.script
              .resolve('../example/dtd_file_system_service_example.dart')
              .toString(),
          toolingDaemonProcess.uri.toString(),
          tmpDirectory.uri.toString(),
        ],
      );
      final lines = <String>[];
      fileSystemServiceExampleProcess.handle(
        stdoutLines: (line) {
          stdout.write('fileSystemServiceProcess stdout: $line');
          lines.add(line);
          final json = jsonDecode(line) as Map<String, Object?>;
          if (json['step'] == 'read') {
            readCompleter.complete();
          } else if (json['step'] == 'listDirectories') {
            listDirCompleter.complete();
          }
        },
        stderrLines: (line) =>
            stderr.write('fileSystemServiceProcess stderr: $line'),
      );

      await readCompleter.future;
      await listDirCompleter.future;

      expect(
        lines,
        containsAll(
          [
            jsonEncode({
              'step': 'read',
              'response': {
                'type': 'FileContent',
                'content': 'Here are some file contents to write.',
              },
            }),
            jsonEncode({
              'step': 'listDirectories',
              'response': {
                'type': 'UriList',
                'uris': ['${tmpDirectory.uri.toString()}a.txt'],
              },
            }),
          ],
        ),
      );
    } finally {
      await tmpDirectory.delete(recursive: true);
      await client?.close();
    }
  });
}
