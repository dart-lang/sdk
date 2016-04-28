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

import 'package:dev_compiler/src/compiler/compiler.dart'
    show missingPartErrorCode, unusedPartWarningCode;

main() {
  group('Hello World', () {
    final argsFile = new File('test/worker/hello_world.args').absolute;
    final inputDartFile = new File('test/worker/hello_world.dart').absolute;
    final outputJsFile = new File('test/worker/hello_world.js').absolute;
    final executableArgs = ['bin/dartdevc.dart', 'compile',];
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
      if (argsFile.existsSync()) argsFile.deleteSync();
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

    test('can compile in basic mode with args in a file', () async {
      argsFile.createSync();
      argsFile.writeAsStringSync(compilerArgs.join('\n'));
      var args = new List.from(executableArgs)..add('@${argsFile.path}');
      var process = await Process.start('dart', args);
      stderr.addStream(process.stderr);
      var futureProcessOutput = process.stdout.map(UTF8.decode).toList();

      expect(await process.exitCode, EXIT_CODE_OK);
      expect((await futureProcessOutput).join(), isEmpty);
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
      helloDart.writeAsStringSync('import "greeting.dart";'
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

  group('Error handling', () {
    final badFileDart = new File('test/worker/bad.dart').absolute;
    final badFileJs = new File('test/worker/bad.js').absolute;

    tearDown(() {
      if (badFileDart.existsSync()) badFileDart.deleteSync();
      if (badFileJs.existsSync()) badFileJs.deleteSync();
    });

    test('incorrect usage', () {
      var result = Process.runSync('dart', ['bin/dartdevc.dart', 'oops',]);
      expect(result.exitCode, 64);
      expect(result.stdout, contains('Could not find a command named "oops"'));
      expect(result.stdout, isNot(contains('#0')));
    });

    test('compile errors', () {
      badFileDart.writeAsStringSync('main() => "hello world"');
      var result = Process.runSync('dart', [
        'bin/dartdevc.dart',
        'compile',
        '--no-source-map',
        '-o',
        badFileJs.path,
        badFileDart.path,
      ]);
      expect(result.exitCode, 1);
      expect(result.stdout, contains("[error] Expected to find ';'"));
    });
  });

  group('Parts', () {
    final partFile = new File('test/worker/greeting.dart').absolute;
    final libraryFile = new File('test/worker/hello.dart').absolute;

    final outJS = new File('test/worker/output.js').absolute;

    setUp(() {
      partFile.writeAsStringSync('part of hello;\n'
          'String greeting = "hello";');
      libraryFile.writeAsStringSync('library hello;\n'
          'part "greeting.dart";\n'
          'main() => print(greeting);\n');
    });

    tearDown(() {
      if (partFile.existsSync()) partFile.deleteSync();
      if (libraryFile.existsSync()) libraryFile.deleteSync();
      if (outJS.existsSync()) outJS.deleteSync();
    });

    test('works if part and library supplied', () {
      var result = Process.runSync('dart', [
        'bin/dartdevc.dart',
        'compile',
        '--no-summarize',
        '--no-source-map',
        '-o',
        outJS.path,
        partFile.path,
        libraryFile.path,
      ]);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(outJS.existsSync(), isTrue);
    });

    test('error if part is not supplied', () {
      var result = Process.runSync('dart', [
        'bin/dartdevc.dart',
        'compile',
        '--no-summarize',
        '--no-source-map',
        '-o',
        outJS.path,
        libraryFile.path,
      ]);
      expect(
          result.stdout,
          startsWith('[error] ${missingPartErrorCode.message} '
              '(test/worker/greeting.dart, line 1, col 1)'));
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 1);
      expect(outJS.existsSync(), isFalse);
    });

    test('warning if part without library is supplied', () {
      var result = Process.runSync('dart', [
        'bin/dartdevc.dart',
        'compile',
        '--no-summarize',
        '--no-source-map',
        '-o',
        outJS.path,
        partFile.path,
      ]);
      expect(
          result.stdout,
          startsWith('[warning] ${unusedPartWarningCode.message} '
              '(test/worker/greeting.dart, line 1, col 1)'));
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(outJS.existsSync(), isTrue);
    });
  });
}

Future<WorkResponse> _readResponse(MessageGrouper messageGrouper) async {
  var buffer = await messageGrouper.next;
  try {
    return new WorkResponse.fromBuffer(buffer);
  } catch (_) {
    var bufferAsString =
        buffer == null ? '' : 'String: ${UTF8.decode(buffer)}\n';
    throw 'Failed to parse response:\nbytes: $buffer\n$bufferAsString';
  }
}
