// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bazel_worker/bazel_worker.dart';
// TODO(jakemac): Remove once this is a part of the testing library.
import 'package:bazel_worker/src/async_message_grouper.dart';
import 'package:bazel_worker/testing.dart';
import 'package:path/path.dart' show dirname, join, joinAll;
import 'package:test/test.dart';

Directory tmp = Directory.systemTemp.createTempSync('ddc_worker_test');
File file(String path) => File(join(tmp.path, joinAll(path.split('/'))));

void main() {
  var baseArgs = <String>[];
  final binDir = dirname(Platform.resolvedExecutable);
  // Note, the bots use the dart binary in the top-level build directory.
  // On windows, this is a .bat file.
  final dartdevc = 'dartdevc${Platform.isWindows ? ".bat" : ""}';
  final executable = binDir.endsWith('bin')
      ? join(binDir, dartdevc)
      : join(binDir, 'dart-sdk', 'bin', dartdevc);
  final executableArgs = <String>[];
  group('DDC: Hello World', () {
    final argsFile = file('hello_world.args');
    final inputDartFile = file('hello_world.dart');
    final outputJsFile = file('out/hello_world.js');
    final compilerArgs = baseArgs +
        [
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
      if (outputJsFile.parent.existsSync()) {
        outputJsFile.parent.deleteSync(recursive: true);
      }
      if (argsFile.existsSync()) argsFile.deleteSync();
    });

    test('can compile in worker mode', () async {
      var args = executableArgs.toList()..add('--persistent_worker');
      var process = await Process.start(executable, args);
      var messageGrouper = AsyncMessageGrouper(process.stdout);

      var request = WorkRequest();
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

      // Try to compile an error.
      inputDartFile.writeAsStringSync('main() { int x = "hello"; }');
      process.stdin.add(protoToDelimitedBuffer(request));

      response = await _readResponse(messageGrouper);
      expect(response.exitCode, 1, reason: response.output);
      expect(
          response.output,
          contains(
              'A value of type \'String\' can\'t be assigned to a variable of type \'int\'.'));

      process.kill();

      // TODO(jakemac): This shouldn't be necessary, but it is for the process
      // to exit properly.
      expect(await messageGrouper.next, isNull);
    });

    test('can compile in basic mode', () {
      var args = executableArgs.toList()..addAll(compilerArgs);
      var result = Process.runSync(executable, args);

      expect(result.exitCode, EXIT_CODE_OK);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(outputJsFile.existsSync(), isTrue);
    });

    test('unknown options', () {
      var args = List<String>.from(executableArgs)
        ..add('--does-not-exist')
        ..addAll(compilerArgs);
      var result = Process.runSync(executable, args);

      expect(result.exitCode, 64);
      expect(result.stdout,
          contains('Could not find an option named "does-not-exist"'));
      expect(result.stderr, isEmpty);
      expect(outputJsFile.existsSync(), isFalse);
    });

    test('unknown options ignored', () {
      var args = List<String>.from(executableArgs)
        ..add('--does-not-exist')
        ..add('--ignore-unrecognized-flags')
        ..addAll(compilerArgs);
      var result = Process.runSync(executable, args);

      expect(result.exitCode, EXIT_CODE_OK);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(outputJsFile.existsSync(), isTrue);
    });

    test('can compile in basic mode with args in a file', () async {
      argsFile.createSync();
      argsFile.writeAsStringSync(compilerArgs.join('\n'));
      var args = executableArgs.toList()..add('@${argsFile.path}');
      var process = await Process.start(executable, args);
      await stderr.addStream(process.stderr);
      var futureProcessOutput = process.stdout.map(utf8.decode).toList();

      expect(await process.exitCode, EXIT_CODE_OK);
      expect((await futureProcessOutput).join(), isEmpty);
      expect(outputJsFile.existsSync(), isTrue);
    });

    test('can compile in basic mode with "legacy" modules', () async {
      var args = List<String>.from(executableArgs)
        ..add('--modules')
        ..add('legacy')
        ..addAll(compilerArgs);
      var result = Process.runSync(executable, args);

      expect(result.exitCode, EXIT_CODE_OK);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(outputJsFile.existsSync(), isTrue);
    });
  });

  group('DDC: Hello World with Summaries', () {
    final greetingDart = file('greeting.dart');
    final helloDart = file('hello.dart');

    final greetingJS = file('greeting.js');
    final greetingSummary = file('greeting.dill');
    final helloJS = file('hello_world.js');

    final greeting2JS = file('greeting2.js');
    final greeting2Summary = file('greeting2.dill');

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
      var result = Process.runSync(
          executable,
          executableArgs +
              baseArgs +
              [
                '--no-source-map',
                '-o',
                greetingJS.path,
                greetingDart.path,
              ]);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(result.exitCode, EXIT_CODE_OK);
      expect(greetingJS.existsSync(), isTrue);
      expect(greetingSummary.existsSync(), isTrue);

      result = Process.runSync(
          executable,
          executableArgs +
              baseArgs +
              [
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

    test('reports error on overlapping summaries', () {
      var result = Process.runSync(
          executable,
          executableArgs +
              baseArgs +
              [
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

      result = Process.runSync(
          executable,
          executableArgs +
              baseArgs +
              [
                '--no-source-map',
                '-o',
                greeting2JS.path,
                greetingDart.path,
              ]);
      expect(result.exitCode, EXIT_CODE_OK);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
      expect(greeting2JS.existsSync(), isTrue);
      expect(greeting2Summary.existsSync(), isTrue);

      result = Process.runSync(
          executable,
          executableArgs +
              baseArgs +
              [
                '--no-source-map',
                '--no-summarize',
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

  group('DDC: Error handling', () {
    final badFileDart = file('bad.dart');
    final badFileJs = file('bad.js');

    tearDown(() {
      if (badFileDart.existsSync()) badFileDart.deleteSync();
      if (badFileJs.existsSync()) badFileJs.deleteSync();
    });

    test('incorrect usage', () {
      var result = Process.runSync(
          executable,
          executableArgs +
              baseArgs +
              [
                'oops',
              ]);
      expect(result.exitCode, 64);
      expect(
          result.stdout, contains('Please specify the output file location.'));
      expect(result.stdout, isNot(contains('#0')));
    });

    test('compile errors', () {
      badFileDart.writeAsStringSync('main() => "hello world"');
      var result = Process.runSync(
          executable,
          executableArgs +
              baseArgs +
              [
                '--no-source-map',
                '-o',
                badFileJs.path,
                badFileDart.path,
              ]);
      expect(result.exitCode, 1);
      expect(result.stdout, contains(RegExp(r"Expected (to find )?\';\'")));
    });
  });

  group('DDC: Parts', () {
    final partFile = file('greeting.dart');
    final libraryFile = file('hello.dart');

    final outJS = file('output.js');

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
      var result = Process.runSync(
          executable,
          executableArgs +
              baseArgs +
              [
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

    test('works if part is not supplied', () {
      var result = Process.runSync(
          executable,
          executableArgs +
              baseArgs +
              [
                '--no-summarize',
                '--no-source-map',
                '-o',
                outJS.path,
                libraryFile.path,
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
    return WorkResponse.fromBuffer(buffer);
  } catch (_) {
    var bufferAsString =
        buffer == null ? '' : 'String: ${utf8.decode(buffer)}\n';
    throw 'Failed to parse response:\nbytes: $buffer\n$bufferAsString';
  }
}
