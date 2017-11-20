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
import 'package:path/path.dart' show join, joinAll;
import 'package:test/test.dart';

File file(String path) => new File(joinAll(path.split('/'))).absolute;

main() {
  var dartdevc = join('bin', 'dartdevc.dart');
  group('Hello World', () {
    final argsFile = file('test/worker/hello_world.args');
    final inputDartFile = file('test/worker/hello_world.dart');
    final outputJsFile = file('test/worker/out/hello_world.js');
    final dartSdkSummary = file('gen/sdk/ddc_sdk.sum');
    final executableArgs = [dartdevc];
    final compilerArgs = [
      '--no-source-map',
      '--no-summarize',
      '--dart-sdk-summary',
      dartSdkSummary.path,
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
      if (outputJsFile.parent.existsSync()) {
        outputJsFile.parent.deleteSync(recursive: true);
      }
      if (argsFile.existsSync()) argsFile.deleteSync();
    });

    test('can compile in worker mode', () async {
      var args = executableArgs.toList()..add('--persistent_worker');
      var process = await Process.start(Platform.executable, args);
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
      var args = executableArgs.toList()..addAll(compilerArgs);
      var result = Process.runSync(Platform.executable, args);

      expect(result.exitCode, EXIT_CODE_OK);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(outputJsFile.existsSync(), isTrue);
    });

    test('unknown options', () {
      var args = new List<String>.from(executableArgs)
        ..add('--does-not-exist')
        ..addAll(compilerArgs);
      var result = Process.runSync(Platform.executable, args);

      expect(result.exitCode, 64);
      expect(result.stdout,
          contains('Could not find an option named "does-not-exist"'));
      expect(result.stderr, isEmpty);
      expect(outputJsFile.existsSync(), isFalse);
    });

    test('unknown options ignored', () {
      var args = new List<String>.from(executableArgs)
        ..add('--does-not-exist')
        ..add('--ignore-unrecognized-flags')
        ..addAll(compilerArgs);
      var result = Process.runSync(Platform.executable, args);

      expect(result.exitCode, EXIT_CODE_OK);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(outputJsFile.existsSync(), isTrue);
    });

    test('can compile in basic mode with args in a file', () async {
      argsFile.createSync();
      argsFile.writeAsStringSync(compilerArgs.join('\n'));
      var args = executableArgs.toList()..add('@${argsFile.path}');
      var process = await Process.start(Platform.executable, args);
      stderr.addStream(process.stderr);
      var futureProcessOutput = process.stdout.map(UTF8.decode).toList();

      expect(await process.exitCode, EXIT_CODE_OK);
      expect((await futureProcessOutput).join(), isEmpty);
      expect(outputJsFile.existsSync(), isTrue);
    });
  });

  group('Hello World with Summaries', () {
    final greetingDart = file('test/worker/greeting.dart');
    final helloDart = file('test/worker/hello.dart');

    final greetingJS = file('test/worker/greeting.js');
    final greetingSummary = file('test/worker/greeting.api.ds');
    final helloJS = file('test/worker/hello_world.js');

    final greeting2JS = file('test/worker/greeting2.js');
    final greeting2Summary = file('test/worker/greeting2.api.ds');

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
      if (greeting2JS.existsSync()) greeting2JS.deleteSync();
      if (greeting2Summary.existsSync()) greeting2Summary.deleteSync();
      if (helloJS.existsSync()) helloJS.deleteSync();
    });

    test('can compile in basic mode', () {
      final dartSdkSummary = file('gen/sdk/ddc_sdk.sum');
      var result = Process.runSync(Platform.executable, [
        dartdevc,
        '--summary-extension=api.ds',
        '--no-source-map',
        '--dart-sdk-summary',
        dartSdkSummary.path,
        '-o',
        greetingJS.path,
        greetingDart.path,
      ]);
      expect(result.exitCode, EXIT_CODE_OK);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(greetingJS.existsSync(), isTrue);
      expect(greetingSummary.existsSync(), isTrue);

      result = Process.runSync(Platform.executable, [
        dartdevc,
        '--no-source-map',
        '--no-summarize',
        '--dart-sdk-summary',
        dartSdkSummary.path,
        '--summary-extension=api.ds',
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

    test('reports error on overlapping summaries', () {
      final dartSdkSummary = file('gen/sdk/ddc_sdk.sum');
      var result = Process.runSync(Platform.executable, [
        dartdevc,
        '--summary-extension=api.ds',
        '--no-source-map',
        '--dart-sdk-summary',
        dartSdkSummary.path,
        '-o',
        greetingJS.path,
        greetingDart.path,
      ]);
      expect(result.exitCode, EXIT_CODE_OK);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(greetingJS.existsSync(), isTrue);
      expect(greetingSummary.existsSync(), isTrue);

      result = Process.runSync(Platform.executable, [
        dartdevc,
        '--summary-extension=api.ds',
        '--no-source-map',
        '--dart-sdk-summary',
        dartSdkSummary.path,
        '-o',
        greeting2JS.path,
        greetingDart.path,
      ]);
      expect(result.exitCode, EXIT_CODE_OK);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(greeting2JS.existsSync(), isTrue);
      expect(greeting2Summary.existsSync(), isTrue);

      result = Process.runSync(Platform.executable, [
        dartdevc,
        '--no-source-map',
        '--no-summarize',
        '--dart-sdk-summary',
        dartSdkSummary.path,
        '--summary-extension=api.ds',
        '-s',
        greetingSummary.path,
        '-s',
        greeting2Summary.path,
        '-o',
        helloJS.path,
        helloDart.path,
      ]);
      // TODO(vsm): Re-enable when we turn this check back on.
      expect(result.exitCode, 0);
      // expect(result.exitCode, 65);
      // expect(result.stdout, contains("conflict"));
      // expect(result.stdout, contains('${toUri(greetingDart.path)}'));
      // expect(helloJS.existsSync(), isFalse);
    });
  });

  group('Error handling', () {
    final dartSdkSummary = file('gen/sdk/ddc_sdk.sum');
    final badFileDart = file('test/worker/bad.dart');
    final badFileJs = file('test/worker/bad.js');

    tearDown(() {
      if (badFileDart.existsSync()) badFileDart.deleteSync();
      if (badFileJs.existsSync()) badFileJs.deleteSync();
    });

    test('incorrect usage', () {
      var result = Process.runSync(Platform.executable, [
        dartdevc,
        '--dart-sdk-summary',
        dartSdkSummary.path,
        'oops',
      ]);
      expect(result.exitCode, 64);
      expect(
          result.stdout, contains('Please include the output file location.'));
      expect(result.stdout, isNot(contains('#0')));
    });

    test('compile errors', () {
      badFileDart.writeAsStringSync('main() => "hello world"');
      var result = Process.runSync(Platform.executable, [
        dartdevc,
        '--no-source-map',
        '--dart-sdk-summary',
        dartSdkSummary.path,
        '-o',
        badFileJs.path,
        badFileDart.path,
      ]);
      expect(result.exitCode, 1);
      expect(result.stdout, contains("[error] Expected to find ';'"));
    });
  });

  group('Parts', () {
    final dartSdkSummary = file('gen/sdk/ddc_sdk.sum');
    final partFile = file('test/worker/greeting.dart');
    final libraryFile = file('test/worker/hello.dart');

    final outJS = file('test/worker/output.js');

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
      var result = Process.runSync(Platform.executable, [
        dartdevc,
        '--no-summarize',
        '--no-source-map',
        '--dart-sdk-summary',
        dartSdkSummary.path,
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

    test('works if part is not supplied', () {
      var result = Process.runSync(Platform.executable, [
        dartdevc,
        '--no-summarize',
        '--no-source-map',
        '--dart-sdk-summary',
        dartSdkSummary.path,
        '-o',
        outJS.path,
        libraryFile.path,
      ]);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(outJS.existsSync(), isTrue);
    });

    test('part without library is silently ignored', () {
      var result = Process.runSync(Platform.executable, [
        dartdevc,
        '--no-summarize',
        '--no-source-map',
        '--dart-sdk-summary',
        dartSdkSummary.path,
        '-o',
        outJS.path,
        partFile.path,
      ]);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(result.exitCode, 0);
      expect(outJS.existsSync(), isTrue);
    });
  });
}

Future<WorkResponse> _readResponse(MessageGrouper messageGrouper) async {
  var buffer = (await messageGrouper.next) as List<int>;
  try {
    return new WorkResponse.fromBuffer(buffer);
  } catch (_) {
    var bufferAsString =
        buffer == null ? '' : 'String: ${UTF8.decode(buffer)}\n';
    throw 'Failed to parse response:\nbytes: $buffer\n$bufferAsString';
  }
}
