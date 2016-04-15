// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bazel_worker/bazel_worker.dart';
// TODO(jakemac): Remove once this is a part of the testing library.
import 'package:bazel_worker/src/async_message_grouper.dart';
import 'package:bazel_worker/testing.dart';
import 'package:test/test.dart';

main() {
  group('Hello World', () {
    final inputDartFile = new File('test/worker/hello_world.dart').absolute;
    final outputJsFile = new File('test/worker/hello_world.js').absolute;
    final executableArgs = [
      'bin/dartdevc.dart',
      'compile',
    ];
    final compilerArgs = [
      '--no-source-map',
      '--no-summarize',
      '-o',
      outputJsFile.path,
      inputDartFile.path,
    ];

    setUp(() {
      inputDartFile.createSync();
      inputDartFile.writeAsStringSync('main() => print("hello world");');
    });

    tearDown(() {
      if (inputDartFile.existsSync()) inputDartFile.deleteSync();
      if (outputJsFile.existsSync()) outputJsFile.deleteSync();
    });

    test('can compile in worker mode', () async {
      var args = new List.from(executableArgs)..add('--persistent_worker');
      var process = await Process.start('dart', args);
      var messageGrouper = new AsyncMessageGrouper(process.stdout);

      var request = new WorkRequest();
      request.arguments.addAll(compilerArgs);
      process.stdin.add(protoToDelimitedBuffer(request));

      var response = await _readResponse(messageGrouper);
      expect(response.exitCode, EXIT_CODE_OK, reason: response.output);
      expect(response.output, isEmpty);

      expect(outputJsFile.existsSync(), isTrue);
      expect(outputJsFile.readAsStringSync(), contains('hello world'));

      /// Now update hello_world.dart and send another [WorkRequest].
      inputDartFile.writeAsStringSync('main() => print("goodbye world");');
      process.stdin.add(protoToDelimitedBuffer(request));

      response = await _readResponse(messageGrouper);
      expect(response.exitCode, EXIT_CODE_OK, reason: response.output);
      expect(response.output, isEmpty);
      expect(outputJsFile.readAsStringSync(), contains('goodbye world'));

      process.kill();

      // TODO(jakemac): This shouldn't be necessary, but it is for the process
      // to exit properly.
      expect(await messageGrouper.next, isNull);
    });

    test('can compile in basic mode', () {
      var args = new List.from(executableArgs)..addAll(compilerArgs);
      var result = Process.runSync('dart', args);

      expect(result.exitCode, EXIT_CODE_OK);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(outputJsFile.existsSync(), isTrue);
    });
  });

  group('Hello World with Summaries', () {
    final greetingDart = new File('test/worker/greeting.dart').absolute;
    final helloDart = new File('test/worker/hello.dart').absolute;

    final greetingJS = new File('test/worker/greeting.js').absolute;
    final greetingSummary = new File('test/worker/greeting.sum').absolute;
    final helloJS = new File('test/worker/hello_world.js').absolute;

    setUp(() {
      greetingDart.writeAsStringSync('String greeting = "hello";');
      helloDart.writeAsStringSync(
          'import "greeting.dart";'
          'main() => print(greeting);');
    });

    tearDown(() {
      if (greetingDart.existsSync()) greetingDart.deleteSync();
      if (helloDart.existsSync()) helloDart.deleteSync();
      if (greetingJS.existsSync()) greetingJS.deleteSync();
      if (greetingSummary.existsSync()) greetingSummary.deleteSync();
      if (helloJS.existsSync()) helloJS.deleteSync();
    });

    test('can compile in basic mode', () {
      var result = Process.runSync('dart', [
        'bin/dartdevc.dart',
        'compile',
        '--no-source-map',
        '-o',
        greetingJS.path,
        greetingDart.path,
      ]);
      expect(result.exitCode, EXIT_CODE_OK);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(greetingJS.existsSync(), isTrue);
      expect(greetingSummary.existsSync(), isTrue);

      result = Process.runSync('dart', [
        'bin/dartdevc.dart',
        'compile',
        '--no-source-map',
        '--no-summarize',
        '-s',
        greetingSummary.path,
        '-o',
        helloJS.path,
        helloDart.path,
      ]);
      expect(result.exitCode, EXIT_CODE_OK);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(helloJS.existsSync(), isTrue);
    });
  });
}

Future<WorkResponse> _readResponse(MessageGrouper messageGrouper) async {
  var buffer = await messageGrouper.next;
  try {
    return new WorkResponse.fromBuffer(buffer);
  } catch (_) {
    throw 'Failed to parse response: \n'
        'bytes: $buffer\n'
        'String: ${new String.fromCharCodes(buffer)}\n';
  }
}
